# frozen_string_literal: true

class RFGW
  require_relative 'maps-get'

  def del_streams(user_streams)
    user_streams = [user_streams] unless user_streams.is_a?(Array)

    user_streams.each do |stream|
      raise "need to specify channel: #{stream}" if stream[:channel].nil?
      raise "need to specify row number: #{stream}" if stream[:row_num].nil?
    end

    del_streams = user_streams.map { |e| [e[:row_num], e[:channel]] }
    query = create_smap_query(:delete, del_streams)

    post_streams(query)
  end

  # add new streams
  def add_streams(user_streams)
    user_streams = [user_streams] unless user_streams.is_a?(Array)

    user_streams.each do |stream|
      raise "need to specify channel: #{stream}" if stream[:channel].nil?
    end

    channels_to_be_added = user_streams.map { |e| e[:channel] }

    # will need existing streams for default ingress port and stream indexes
    existing_streams = {}
    channels_to_be_added.uniq.each do |channel|
      next if existing_streams.key?(channel)

      existing_streams[channel] = get_stream_map(channel)
    end

    # get usable stream indexes based on existing streams
    usable_stream_indexes = {}
    channels_to_be_added.uniq.each do |channel|
      total_streams = channels_to_be_added.count(channel)
      stream_indexes = get_new_stream_indexes(existing_streams[channel], total_streams)
      usable_stream_indexes[channel] = stream_indexes
    end

    # ingress port
    get_windmark # set default ingress port
    user_streams.each do |stream| # get existing channel stream's first ingress port
      next unless stream[:port].nil? || stream[:port].empty?

      channel = stream[:channel]
      if existing_streams.key?(channel) && existing_streams[channel].size.positive?
        stream[:port] = existing_streams[channel].first[:port]
      end
    end

    new_streams = []
    user_streams.each do |user_stream|
      channel = user_stream[:channel]
      next_stream_index = usable_stream_indexes[channel].shift
      new_streams << create_new_stream(user_stream, next_stream_index)
    end

    query = create_smap_query(:insert, new_streams)

    post_streams(query)
  end

  private

  def create_smap_query(action, streams)
    operations = {
      'DELETE' => 0,
      'MODIFY' => 0,
      'INSERT' => 0
    }
    params = 'smapQueryString='

    # just handeling add for now
    if action == :insert
      operations['INSERT'] += streams.size

      params << operations.map { |k, v| "#{k}##{v}" }.join('#') + '#'
      params << streams.map { |stream| stream.join('#') }.join('#')
    elsif action == :delete
      operations['DELETE'] += streams.size

      params << "DELETE##{operations.delete('DELETE')}#"
      params << streams.map { |stream| stream.join('#') }.join('#') + '#'
      params << operations.map { |k, v| "#{k}##{v}" }.join('#')
    end

    params
  end

  def create_new_stream(stream_hash, stream_index = nil)
    stream_hash.transform_keys!(&:to_sym)
    stream_hash.transform_values!(&:to_s)

    default_stream = Marshal.load(Marshal.dump(DEFAULT_PARSED_STREAM))
    stream_hash[:stream_index] = stream_index.to_s unless stream_index.nil?
    new_stream = default_stream.merge(stream_hash)

    construct_raw_stream(new_stream)
  end

  def get_windmark
    url = "#{@base_url}/cgi/getwindmark.cgi?"
    url << 'sca&rfgw1GbePortOperMode&rfgw1GeneralMPTSDefaults'

    res = @agent.get(url)
    data = res.body.split('&')
    port_mode = data[0].to_s
    data[1].to_s # some logic here I don't care about for what I'm doing.
    # has to do with the first blocked PID

    if %w[1 3 4].include?(port_mode) # dual port mode,loop back mode # pair1 as default
      DEFAULT_PARSED_STREAM[:port] = 'Pair-1'
    elsif %w[2].include?(port_mode) # independent port mode # port1 as default
      DEFAULT_PARSED_STREAM[:port] = 'Port-1'
    end
  end

  def post_streams(query)
    url = "#{@base_url}/fs/stream_map.html"

    res = @agent.post(url, query, 'Content-Type' => 'application/x-www-form-urlencoded')
    return true if res.code == '200' && res.body == '&0'

    # this only means the request went through, not that X was added/deleted

    raise "problem hitting stream_map.html: http code: #{res.code} - #{res.body}"
  end

  def get_new_stream_indexes(existing_streams, new_streams_count)
    # all this does is get the lowest possible stream indexes
    # given what's there and how many new streams are going to be added
    # existing_streams = get_stream_map(channel)
    existing_indexes = existing_streams.map { |e| e[:stream_index].to_i }

    new_total = existing_indexes.size + new_streams_count

    possible_indexes = (1..new_total).to_a
    unused_indexes = possible_indexes - existing_indexes

    unused_indexes.shift(new_streams_count)
  end
end

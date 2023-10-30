class RFGW
  require_relative 'maps-post'

  # not sure what happens with single stream or no streams on channel, check it out
  def get_raw_stream_map(start_channel, end_channel=start_channel)
    query = ['GET', start_channel.to_s, end_channel.to_s, 0, 0]
    streams = get_stream(query)

    while streams[-1][0] == 'cur_row'
      cur_row, stream_index = streams[-1][1], streams[-1][3]
      streams.pop
      query = ['GET', start_channel, end_channel, cur_row, stream_index]
      res = get_stream(query)
      res.each{|row| streams << row}
      streams.delete(['end'])
    end
    streams.delete(['end']) # even better way to handle no pagination

    streams
  end

  def get_stream_map(start_channel, end_channel=start_channel)
    streams = get_raw_stream_map(start_channel, end_channel)
    parsed = []
    streams.each do |stream|
      parsed << parse_stream(stream)
    end

    parsed
  end

  def get_stream(params)
    url = @base_url + '/stream/stream.cgi?'
    url << params.join('&')

    res = @agent.get(url)
    data = res.body.split('&')
    data.map!{|e| e.split(',')}
  end

  # my own method to create a human-readable hash
  # necessary for making adding/manipulating much easier
  def parse_stream(row)
    if row.size < 22
      raise "row doesn't look right for parsing: #{row}"
    end
    parsed_row = {}

    # base (top row in gui)
    parsed_row[:row_num]      = row[0]
    parsed_row[:stream_index] = row[-1] # needed for adding new ones
    parsed_row[:channel]      = row[1]  # not in RFGW GUI, but important
    parsed_row[:display_channel] = display_channel(row[1])
    parsed_row[:destination_ip]  = row[2]
    parsed_row[:udp_port]     = row[3]
    parsed_row[:active]       = map_to_string(row[4], :active_to_string)
    parsed_row[:port]         = map_to_string(row[5], :port_to_string)
    parsed_row[:type]         = map_to_string(row[6], :stream_type)
    parsed_row[:program_in]   = row[7]
    parsed_row[:program_out]  = row[8]
    parsed_row[:pmv]          = row[9]
    parsed_row[:data_rate]    = row[10]
    parsed_row[:psipeas_pres] = map_to_string(row[19], :psip_eas)
    
    # advanced (bottom row in gui)
    parsed_row[:source_primary]    = row[11]
    parsed_row[:source_secondary]  = row[12]
    parsed_row[:source_tertiary]   = row[13]
    parsed_row[:source_quaternary] = row[14]
    
    parsed_row[:ignore_udp] = map_to_string(row[15], :udp_to_str)
    parsed_row[:prc]        = map_to_string(row[16], :pcr_to_str)
    parsed_row[:mpts_mode]  = map_to_string(row[17], :mode_to_str)
    parsed_row[:mpts_ref]   = row[18]
    parsed_row[:blocked_pids_size] = row[20] # not necessary or in GUI
                                           # but it was the only one missing
    parsed_row[:blocked_pids] = row[21..-2].join(',')

    return parsed_row
  end

  # this is taking my custom hash i've created
  # and turning it back into the CGI's raw array of integers and IPs
  def construct_raw_stream(stream)
    row = []
    row << stream[:row_num] # 0
    row << stream[:channel] # 1
    row << stream[:destination_ip] # 2
    row << stream[:udp_port] # 3

    row << string_to_map(stream[:active], :active_to_string) # 4
    row << string_to_map(stream[:port], :port_to_string) # 5
    row << string_to_map(stream[:type], :stream_type) # 6
    row << stream[:program_in] # 7
    row << stream[:program_out] # 8
    row << stream[:pmv] # 9
    row << stream[:data_rate] # 10

    row << stream[:source_primary]    # 11
    row << stream[:source_secondary]  # 12
    row << stream[:source_tertiary]   # 13
    row << stream[:source_quaternary] # 14

    row << string_to_map(stream[:ignore_udp], :udp_to_str) # 15
    row << string_to_map(stream[:prc], :pcr_to_str) # 16
    row << string_to_map(stream[:mpts_mode], :mode_to_str) # 17
    row << stream[:mpts_ref] # 18
    row << string_to_map(stream[:psipeas_pres], :psip_eas) # 19

    row << stream[:blocked_pids_size] # 20
    row << stream[:blocked_pids].split(',') # 21-53

    row << stream[:stream_index] # 54

    row.flatten
  end

  def display_channel(chn)
    chn = chn.to_i
    offset = chn % 16
    cardId = (chn-offset)/16 + 1
    chnId = offset % 8
    portId = (offset-chnId)/8 + 1
    chnId += 1

    cardId.to_s + "/" + portId.to_s + "." + chnId.to_s
  end

  def raw_channel(display_channel)
    unless display_channel =~ /^(\d+)\/(\d+)\.(\d+)$/
      raise "I do not know how to handle input channel: #{display_channel}"
    end

    cardId, portId, chnId = $1.to_i, $2.to_i, $3.to_i

    offset = (portId - 1) * 8
    offset += chnId - 1

    cardId -= 1
    channel = (cardId * 16) + offset

    channel.to_s
  end

  def convert_to_display_channel(channel)
    if channel.to_s =~ /^\d+$/
      return display_channel(channel)
    elsif channel =~ /^(\d+)\/(\d+)\.(\d+)$/
      return channel
    end
  end

  def convert_to_raw_channel(channel)
    channel = channel.to_s
    if channel =~ /^(\d+)\/(\d+)\.(\d+)$/
      return raw_channel(channel)
    elsif channel =~ /^\d+$/
      return channel
    end
  end

  def map_to_string(cell_key, table_key)
    cell_key = cell_key.to_s
    field_hash = TABLE_MAPPING[table_key]

    field_hash.has_key?(cell_key) ? field_hash[cell_key] : 'Unknown'
  end

  def string_to_map(field_value, table_key)
    field_hash = TABLE_MAPPING[table_key]
    matches = field_hash.select{|k,v| v == field_value}
    unless matches.empty? || matches.size != 1
      return matches.keys.first
    end

    raise "could not reverse string to map #{field_value} for #{table_key}"
  end

  # more for documentation purposes
  DEFAULT_RAW_STREAM = ["0", "0", "0.0.0.0", "00000", "1", "3", "1", "0", "1", "0", "0", "0.0.0.0", "0.0.0.0", "0.0.0.0", "0.0.0.0", "2", "1", "1", "0", "1", "32", "0", "8191", "-1", "-1", "-1", "-1", "-1", "-1", "-1", "-1", "-1", "-1", "-1", "-1", "-1", "-1", "-1", "-1", "-1", "-1", "-1", "-1", "-1", "-1", "-1", "-1", "-1", "-1", "-1", "-1", "-1", "-1", "0"]

  DEFAULT_PARSED_STREAM = {
    :row_num=>"0",
    :stream_index=>"0",
    :channel=>"0",
    :display_channel=>"1/1.1",
    :destination_ip=>"0.0.0.0",
    :udp_port=>"00000",
    :active=>"True",
    :port=>"Pair-1",
    :type=>"SPTS",
    :program_in=>"0",
    :program_out=>"1",
    :pmv=>"0",
    :data_rate=>"0",
    :psipeas_pres=>"None",
    :source_primary=>"0.0.0.0",
    :source_secondary=>"0.0.0.0",
    :source_tertiary=>"0.0.0.0",
    :source_quaternary=>"0.0.0.0",
    :ignore_udp=>"False",
    :prc=>"From PMT",
    :mpts_mode=>"Break Into SPTS",
    :mpts_ref=>"0",
    :blocked_pids_size=>"32",
    :blocked_pids=> "0,8191,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1"
  }

  TABLE_MAPPING = {
    # base table
    :active_to_string => {
      '1' => 'True',
      '2' => 'False',
      '50' => 'Delete'
    },
    :port_to_string => {
      '3'  => 'Pair-1',
      '12' => 'Pair-2',
      '1'  => 'Port-1',
      '2'  => 'Port-2',
      '4'  => 'Port-3',
      '8'  => 'Port-4'
    },
    :stream_type => {
      '1' => 'SPTS',
      '2' => 'MPTS',
      '3' => 'Plant',
      '4' => 'Data'
    },
    :psip_eas => {
      '1' => 'None',
      '2' => 'PSIP',
      '3' => 'EAS'
    },
    
    # advanced
    :udp_to_str => {
      '1' => 'True',
      '2' => 'False'
    },
    :pcr_to_str => {
      '1' => 'From PMT',
      '2' => 'First Detected'
    },
    :mode_to_str => {
      '1' => 'Break Into SPTS',
      '2' => 'One Stream'
    }
  }
end

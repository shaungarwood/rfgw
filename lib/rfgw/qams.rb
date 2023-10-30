# frozen_string_literal: true

class RFGW
  def get_table_data(path, form = {})
    url = "#{@base_url}/common/getTableData.cgi?"
    url << path
    unless form.empty?
      url << '&'
      url << form.map { |k, v| "#{k}=#{v}" }.join('&')
    end

    res = @agent.get(url)
    vals = res.body.split('&')

    state = vals[2]
    raise "Got bad state back from #{url}: #{state}" if state != 'Success'

    vals
  end

  def qam_channel_table(channel = 0)
    get_table_data('QAM_CHANNEL_TABLE', { 'chan' => channel })
  end

  def rf_port_table(port = 0)
    port_data = get_table_data('RF_PORT_TABLE', { 'port' => port })
    puts port_data

    # not returning this data, but can
    annex_text = ['', 'Unknown', 'Other', 'ITU-A', 'ITU-B', 'ITU-C']
    annex_text[port_data[3].to_i]

    port_data[4]

    port_control_text = %w[NA On Off]
    spacing_text = %w[NA 6 7 8]
    mod_text = ['NA', 'NA', 'NA', 'QAM 64', 'QAM 256']
    comb_chan_text = %w[None Single Dual Triple Quad]

    port_table = port_data[5..]
    port_table.size
    whatever = []
    # not doing rf port number, but whatever
    port_table.each do |row|
      n = row.split(',')

      new_row = {}
      new_row[:port_control] = port_control_text[n[0].to_i]
      new_row[:spacing]      = spacing_text[n[1].to_i]
      new_row[:modulation]   = mod_text[n[2].to_i]
      new_row[:output_level] = n[3].to_i / 10.0
      new_row[:symbol_rate]  = n[4].to_i / 1_000_000.0
      # interleave level group 1: n[5]
      # interleave level group 2: n[6]

      new_row[:channel_mode_grp1] = comb_chan_text[n[7].to_i]
      new_row[:center_freq_grp1]  = n[8]
      new_row[:channel_num_grp1]  = n[9]

      new_row[:channel_mode_grp2] = comb_chan_text[n[10].to_i]
      new_row[:center_freq_grp2]  = n[11]
      new_row[:channel_num_grp2]  = n[12]

      new_row[:service_grp_id] = n[13]

      whatever << new_row
    end

    whatever
  end
end

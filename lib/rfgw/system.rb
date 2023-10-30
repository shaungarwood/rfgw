# frozen_string_literal: true

class RFGW
  def get_version
    res = @agent.get("#{@base_url}/download/download.cgi?FW_VERSION&Read")
    vals = res.body.split('&')

    raise "Unexcpted response - #{res.code}: #{res.body}" unless vals.size == 3

    keys = %i[ip active_release inactive_release]
    Hash[keys.zip(vals)]
  end

  def get_download(whatever)
    url = "#{@base_url}/download/download.cgi?"
    url << whatever.join('&')
    res = @agent.get(url)
    res.body.split('&')
  end

  def get_ftp_server
    query = ['CONFIGFTPRESET']
    data = get_download(query)
    ftp = {}
    # data[0] this is just the rfgw ip, i think
    ftp[:server] = data[1]
    ftp[:user] = data[2]
    ftp[:pass] = data[3]
    ftp
  end

  def test_ftp(ip, user, pass)
    # http://10.254.25.71/download/download.cgi?FTP_TEST10.100.198.23&anonymous&a@axz.com&
  end

  def get_last_backup
    query = ['CONFIG_LAST']
    data = get_download(query)
    lastb = {}
    # data[0] is own ip, not useful
    lastb[:saved_date]      = data[1]
    lastb[:backup_filename] = data[2]
    lastb[:backup_date]     = data[3]
    lastb
  end

  def get_next_backup
    query = ['CFG_BKUPRESTORE']
    data = get_download(query)
    nextb = {}
    nextb[:path] = data[1]
    nextb[:file] = data[5]
    nextb
  end
end

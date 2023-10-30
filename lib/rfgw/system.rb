class RFGW
  def get_version
    res = @agent.get(@base_url + '/download/download.cgi?FW_VERSION&Read')
    vals = res.body.split("&")

    if vals.size == 3
      keys = [:ip, :active_release, :inactive_release]
      return Hash[keys.zip(vals)]
    else
      raise "Unexcpted response - #{res.code}: #{res.body}"
    end
  end

  def get_download(whatever)
    url = @base_url + '/download/download.cgi?'
    url << whatever.join('&')
    res = @agent.get(url)
    data = res.body.split('&')
    return data
  end

  def get_ftp_server
    query = ['CONFIGFTPRESET']
    data = get_download(query)
    ftp = {}
    # data[0] this is just the rfgw ip, i think
    ftp[:server] = data[1]
    ftp[:user], ftp[:pass] = data[2], data[3]
    return ftp
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
    return lastb
  end

  def get_next_backup
    query = ['CFG_BKUPRESTORE']
    data = get_download(query)
    nextb = {}
    nextb[:path] = data[1]
    nextb[:file] = data[5]
    return nextb
  end
end

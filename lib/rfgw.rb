# frozen_string_literal: true

require 'mechanize'

require_relative 'rfgw/system'
require_relative 'rfgw/qams'
require_relative 'rfgw/maps'

class RFGW
  def initialize(ip)
    @base_url = "http://#{ip}"

    @agent = Mechanize.new
    @agent.idle_timeout = nil
    @agent.read_timeout = 100_000
    @agent.user_agent_alias = 'Windows Mozilla'
    @agent.redirect_ok = true
  end

  def get(whatever)
    url = @base_url + whatever

    @agent.get(url)
  end
end

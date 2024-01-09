#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/rfgw'
require 'json'

raise 'please supply IP of rfgw' if ARGV.empty?

d = RFGW.new(ARGV[0])

info = {}
info[:version]     = d.get_version
info[:ftp_server]  = d.get_ftp_server
info[:last_backup] = d.get_last_backup
info[:next_backup] = d.get_next_backup
info[:download]    = d.get_download

puts JSON.pretty_generate(info)

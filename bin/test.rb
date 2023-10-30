#!/usr/bin/env ruby
# frozen_string_literal: true

require 'pry'
require_relative '../lib/rfgw'

d = RFGW.new(ARGV[0])

puts 'this'
binding.pry
puts 'le fin'

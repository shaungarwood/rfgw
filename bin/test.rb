#!/usr/bin/env ruby

require 'pry'
require_relative '../lib/rfgw'

d = RFGW.new(ARGV[0])

puts "this"
binding.pry
puts "le fin"

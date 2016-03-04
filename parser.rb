#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'

require 'nokogiri'
require 'optparse'

options = {}
OptionParser.new do |opts|
	opts.banner = "Usage: parser.rb [options]"

	opts.on('-f', '--filename NAME', 'XML file name') { |v| options[:filename] = v }
end.parse!

doc = Nokogiri::XML(File.open(options[:filename])) do |config|
  config.options = Nokogiri::XML::ParseOptions::STRICT | Nokogiri::XML::ParseOptions::NONET
end
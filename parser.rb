#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'

require 'nokogiri'
require 'optparse'
require 'solid_assert'

SolidAssert.enable_assertions

options = {}

optparse = OptionParser.new do |opts|
	opts.banner = "Usage: parser.rb -f <xml filename> [ -o <output filename> ]"
	opts.on('-f', '-x', '--xml input-filename', 'XML file name') { |v| options[:filename] = v }
	opts.on('-o', '-h', '--html output-filename', 'HTML file name') { |v| options[:output] = v }
end

begin
	optparse.parse!
	mandatory = [:filename]
  missing = mandatory.select{ |param| options[param].nil? }
  unless missing.empty?     
    puts "Missing options: #{missing.join(', ')}"  
    puts optparse                                    
    exit               
  end  
rescue OptionParser::InvalidOption, OptionParser::MissingArgument 
	puts $!.to_s # Friendly output when parsing fails
  puts optparse                                                     
  exit      
end

begin
	@xml = Nokogiri::XML(File.open(options[:filename])) do |config|
		config.options = Nokogiri::XML::ParseOptions::STRICT | Nokogiri::XML::ParseOptions::NONET
	end
rescue Nokogiri::XML::SyntaxError => e
	puts "caught exception: #{e}"
end

begin assert @xml.root.name == "network" rescue abort "Ensure that the <network> tag is at the root" end

begin
	assert @xml.root.first_element_child.name == "intersection" && @xml.root.elements.size == 1
rescue
	abort "Must have one root <intersection> tag"
end

def draw_intersection(node, index, html)
	if node.name == "road" then
		#draw three lines
		ang = @angle*index

		x_dist = Math.cos(ang)*@default_dist
		y_dist = Math.sin(ang)*@default_dist

		x_start = @start_point + @intersection_radius*Math.cos(ang)
		x_start_1 = x_start + @lane_width*Math.cos(ang - Math::PI/2)
		x_start_2 = x_start + @lane_width*Math.cos(ang + Math::PI/2)

		y_start = @start_point + @intersection_radius*Math.sin(ang)
		y_start_1 = y_start + @lane_width*Math.sin(ang - Math::PI/2)
		y_start_2 = y_start + @lane_width*Math.sin(ang + Math::PI/2)

		html.line(:x1 => x_start_1, :x2 => x_start_1+x_dist, :y1 => y_start_1, :y2 => y_start_1+y_dist)
		html.line.dashed(:x1 => x_start, :x2 => x_start+x_dist, :y1 => y_start, :y2 => y_start+y_dist)
		html.line(:x1 => x_start_2, :x2 => x_start_2+x_dist, :y1 => y_start_2, :y2 => y_start_2+y_dist)
	end

	if node.name == "avenue" then
		#draw five lines
		ang = @angle*index

		x_dist = Math.cos(ang)*@default_dist
		y_dist = Math.sin(ang)*@default_dist

		x_start = @start_point + @intersection_radius*Math.cos(ang)
		x_start_1 = x_start + 2*@lane_width*Math.cos(ang - Math::PI/2)
		x_start_2 = x_start + @lane_width*Math.cos(ang - Math::PI/2)
		x_start_3 = x_start + @lane_width*Math.cos(ang + Math::PI/2)
		x_start_4 = x_start + 2*@lane_width*Math.cos(ang + Math::PI/2)

		y_start = @start_point + @intersection_radius*Math.sin(ang)
		y_start_1 = y_start + 2*@lane_width*Math.sin(ang - Math::PI/2)
		y_start_2 = y_start + @lane_width*Math.sin(ang - Math::PI/2)
		y_start_3 = y_start + @lane_width*Math.sin(ang + Math::PI/2)
		y_start_4 = y_start + 2*@lane_width*Math.sin(ang + Math::PI/2)

		html.line(:x1 => x_start_1, :x2 => x_start_1+x_dist, :y1 => y_start_1, :y2 => y_start_1+y_dist)
		html.line.dashed(:x1 => x_start_2, :x2 => x_start_2+x_dist, :y1 => y_start_2, :y2 => y_start_2+y_dist)
		html.line(:x1 => x_start, :x2 => x_start+x_dist, :y1 => y_start, :y2 => y_start+y_dist)
		html.line.dashed(:x1 => x_start_3, :x2 => x_start_3+x_dist, :y1 => y_start_3, :y2 => y_start_3+y_dist)
		html.line(:x1 => x_start_4, :x2 => x_start_4+x_dist, :y1 => y_start_4, :y2 => y_start_4+y_dist)
	end

	if node.name == "street" then
		#draw two lines
		ang = @angle*index

		x_dist = Math.cos(ang)*@default_dist
		y_dist = Math.sin(ang)*@default_dist

		x_start = @start_point + @intersection_radius*Math.cos(ang)
		x_start_1 = x_start + 0.8*@lane_width*Math.cos(ang - Math::PI/2)
		x_start_2 = x_start + 0.8*@lane_width*Math.cos(ang + Math::PI/2)

		y_start = @start_point + @intersection_radius*Math.sin(ang)
		y_start_1 = y_start + 0.8*@lane_width*Math.sin(ang - Math::PI/2)
		y_start_2 = y_start + 0.8*@lane_width*Math.sin(ang + Math::PI/2)

		html.line(:x1 => x_start_1, :x2 => x_start_1+x_dist, :y1 => y_start_1, :y2 => y_start_1+y_dist)
		html.line(:x1 => x_start_2, :x2 => x_start_2+x_dist, :y1 => y_start_2, :y2 => y_start_2+y_dist)
	end
end

#Constants
@default_dist = 200
@lane_width = 20
@start_point = 250
@intersection_radius = 50

builder = Nokogiri::HTML::Builder.new do |html|
	html.html {
		html.head() {
			html.style "svg { border: 2px solid black; } line { stroke: rgb(255,0,0); stroke-width:2 } .dashed { stroke-dasharray: 10, 10 }"

		}
    html.body() {
			html.svg(:width => "500", :height => "500") {

				

				@base_intersection_set = @xml.at_css("intersection").elements
				@angle = 2*Math::PI / @base_intersection_set.size

				@base_intersection_set.each_with_index do |node, index|

					begin assert node.name != "intersection" rescue
						abort "Can't have <intersection> tag within an <intersection> tag"
					end

					draw_intersection node, index, html
				end

			}
    }
  }
end
			


if options[:output] == nil then
	File.write('diagram.html', builder.to_html)
else
	File.write(options[:output], builder.to_html)
end



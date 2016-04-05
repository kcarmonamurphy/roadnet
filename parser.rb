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

#Constants
@default_length = 200
@lane_width = 20
@intersection_radius = 50

def draw_intersection(node, html, cx, cy)
	
	width_arr = Array.new
	height_arr = Array.new
	
	max_width = 0
	max_height = 0
	min_width = 0
	min_height = 0
	
	angle = 2*Math::PI / node.elements.size
	
	angle_offset = node.key?("angle-offset") ? (node.attribute("angle-offset").value.to_f)*Math::PI/180 : 0
	
	intersection_offset = node.key?("intersection-offset") ? (node.attribute("intersection-offset").value.to_f)*Math::PI/180 : 0

	intersection_radius = node.key?("intersection-radius") ? (node.attribute("intersection-radius").value.to_f) : @intersection_radius
	
	html.circle(:cx => cx, :cy => cy, :r => intersection_radius, :stroke => "red", :fill => "white")
	
	node.elements.each_with_index do |node, index|
		
		length = node.key?("length") ? (node.attribute("length").value.to_f) : @default_length
		
		ang = (angle + angle_offset)*index + intersection_offset
		x_dist = Math.cos(ang)*length
		y_dist = Math.sin(ang)*length
		
		x_radius = Math.cos(ang)*intersection_radius
		y_radius = Math.sin(ang)*intersection_radius
		
		x_start = cx + intersection_radius*Math.cos(ang)
		y_start = cy + intersection_radius*Math.sin(ang)
					
		if node.name == "road"
			#draw three lines

			x_start_1 = x_start + @lane_width*Math.cos(ang - Math::PI/2)
			x_start_2 = x_start + @lane_width*Math.cos(ang + Math::PI/2)

			y_start_1 = y_start + @lane_width*Math.sin(ang - Math::PI/2)
			y_start_2 = y_start + @lane_width*Math.sin(ang + Math::PI/2)

			html.line(:x1 => x_start_1, :x2 => x_start_1+x_dist, :y1 => y_start_1, :y2 => y_start_1+y_dist)
			html.line.dashed(:x1 => x_start, :x2 => x_start+x_dist, :y1 => y_start, :y2 => y_start+y_dist)
			html.line(:x1 => x_start_2, :x2 => x_start_2+x_dist, :y1 => y_start_2, :y2 => y_start_2+y_dist)

		elsif node.name == "avenue"
			#draw five lines

			x_start_1 = x_start + 2*@lane_width*Math.cos(ang - Math::PI/2)
			x_start_2 = x_start + @lane_width*Math.cos(ang - Math::PI/2)
			x_start_3 = x_start + @lane_width*Math.cos(ang + Math::PI/2)
			x_start_4 = x_start + 2*@lane_width*Math.cos(ang + Math::PI/2)

			y_start_1 = y_start + 2*@lane_width*Math.sin(ang - Math::PI/2)
			y_start_2 = y_start + @lane_width*Math.sin(ang - Math::PI/2)
			y_start_3 = y_start + @lane_width*Math.sin(ang + Math::PI/2)
			y_start_4 = y_start + 2*@lane_width*Math.sin(ang + Math::PI/2)

			html.line(:x1 => x_start_1, :x2 => x_start_1+x_dist, :y1 => y_start_1, :y2 => y_start_1+y_dist)
			html.line.dashed(:x1 => x_start_2, :x2 => x_start_2+x_dist, :y1 => y_start_2, :y2 => y_start_2+y_dist)
			html.line(:x1 => x_start, :x2 => x_start+x_dist, :y1 => y_start, :y2 => y_start+y_dist)
			html.line.dashed(:x1 => x_start_3, :x2 => x_start_3+x_dist, :y1 => y_start_3, :y2 => y_start_3+y_dist)
			html.line(:x1 => x_start_4, :x2 => x_start_4+x_dist, :y1 => y_start_4, :y2 => y_start_4+y_dist)

		elsif node.name == "street"
			#draw two lines

			x_start_1 = x_start + 0.8*@lane_width*Math.cos(ang - Math::PI/2)
			x_start_2 = x_start + 0.8*@lane_width*Math.cos(ang + Math::PI/2)

			y_start_1 = y_start + 0.8*@lane_width*Math.sin(ang - Math::PI/2)
			y_start_2 = y_start + 0.8*@lane_width*Math.sin(ang + Math::PI/2)

			html.line(:x1 => x_start_1, :x2 => x_start_1+x_dist, :y1 => y_start_1, :y2 => y_start_1+y_dist)
			html.line(:x1 => x_start_2, :x2 => x_start_2+x_dist, :y1 => y_start_2, :y2 => y_start_2+y_dist)

		else
			abort "Invalid type in XML"
			
		end
			
		width_arr << x_start + x_dist + 2*x_radius
		height_arr << y_start + y_dist + 2*y_radius

		max_width, min_width, max_height, min_height = draw_intersection(node, html, x_start+x_dist, y_start+y_dist)

		width_arr << max_width
		width_arr << min_width
		height_arr << max_height
		height_arr << min_height
			
		max_width = width_arr.max
		min_width = width_arr.min
		max_height = height_arr.max
		min_height = height_arr.min
			
	end
			
	return max_width, min_width, max_height, min_height
end

builder = Nokogiri::HTML::Builder.new do |html|
	html.html {
		html.head {
			html.style "svg { border: 2px solid black; } line { stroke: rgb(255,0,0); stroke-width:2 } .dashed { stroke-dasharray: 10, 10 }"
		}
    html.body {
			html.h1.title "Roadnet: XML to SVG road networks converter"
			html.svg {
				html.g {
					@max_width, @min_width, @max_height, @min_height = draw_intersection(@xml.root, html, 0, 0)
				}
			}
    }
  }
end
		
@width = @max_width - @min_width
@height = @max_height - @min_height
		
@html = Nokogiri::HTML::DocumentFragment.parse builder.to_html
@html.at_css("svg")["width"] = @width
@html.at_css("svg")["height"] = @height
		@html.at_css("g")["style"] = "transform: translate(" + (-@min_width).to_s + "px, " + (-@min_height).to_s + "px)"
		
if options[:output] == nil then
	File.write('diagram.html', @html)
else
	File.write(options[:output], @html)
end



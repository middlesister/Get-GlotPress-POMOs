#!/usr/bin/env ruby
require 'rubygems'
require 'hpricot'
require 'open-uri'
require 'net/http'

=begin
Downloads .mo and .po files from the translations of a specific project on translate.thematictheme.com.


Copyright (c) 2012 Paul Gibbs

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
=end

# If required parameters are missing, bail out
if ARGV[0].nil? or ARGV[1].nil?
	puts 'Usage: get-translate-pomos.rb PROJECT VERSION'
	puts "\tPROJECT: URL slug for a project listed at http://translate.thematictheme.com/projects/. "
	puts "\tVERSION: A sub-project, or version, of the PROJECT. e.g. 1.6.x"
	puts ''
	abort
end

puts "Finding translations for #{ARGV[0]} #{ARGV[1]}..."
translations = []

# Load the appropriate project page
begin
	doc = Hpricot( open( "http://translate.thematictheme.com/projects/#{ARGV[0]}/#{ARGV[1]}" ).read )
rescue => error
    abort( "An error occured when trying to load http://translate.thematictheme.com/projects/#{ARGV[0]}/#{ARGV[1]}: #{error}" )
end

# Iterate through each table row
doc.search( '.translation-sets tbody tr' ).each do |row|
	base_url   = row.search( 'td strong a' ).first[:href]
	completion = row.search( 'td.percent'  ).inner_html.gsub( /\n/, '' )
	lang_code  = base_url.split( '/' ).fetch( -2 ).gsub( /[^aA0-zZ9.\-]/, '_' );
	language   = row.search( 'td strong a' ).inner_html.gsub( /\n/, '' )

	# Let's only work with translations that are at least 10% complete
	if completion.to_i < 10
		next
	end

	translations.push( { :base_url => base_url, :lang_code => lang_code, :language => language } );
end

puts "Downloading valid translations for #{translations.count} languages..."

translation_maps = [
];

# Open a HTTP connection
Net::HTTP.start( 'translate.thematictheme.com' ) do |http|
	begin

		# Create output directory exists
		begin
			Dir.mkdir( File.join( Dir.pwd, 'languages' ) )
		rescue
		end

		# Iterate through each translation
		translations.each do |translation|
			puts translation[:language]

			# See if there's a way to automagically figure this out from GlotPress -- or build a big hashmap
			file_name = translation[:lang_code];
			case file_name
			when 'cs'
				file_name = 'cs_CZ'
            when 'da'
				file_name = 'da_DK'
            when 'de'
				file_name = 'de_DE'
            when 'es'
				file_name = 'es_ES'
            when 'fa'
				file_name = 'fa_IR'
            when 'fr'
				file_name = 'fr_FR'
            when 'he'
				file_name = 'he_IL'
            when 'hu'
				file_name = 'hu_HU'
            when 'id'
				file_name = 'id_ID'
            when 'is'
				file_name = 'is_IS'
            when 'it'
				file_name = 'it_IT'
            when 'ko'
				file_name = 'ko_KR'
            when 'nb'
				file_name = 'nb_NO'
            when 'nl'
				file_name = 'nl_NL'
            when 'pl'
				file_name = 'pl_PL'
            when 'pt-br'
				file_name = 'pt_BR'
            when 'pt'
				file_name = 'pt_PT'
            when 'ro'
				file_name = 'ro_RO'
            when 'ru'
				file_name = 'ru_RU'
            when 'sk'
				file_name = 'sk_SK'
            when 'sr'
				file_name = 'sr_RS'
            when 'sv'
				file_name = 'sv_SE'
            when 'tr'
				file_name = 'tr_TR'
			when 'zh-cn'
				file_name = 'zh_CN'
			when 'zh-hk'
				file_name = 'zh_HK'
            when 'zh-tw'
				file_name = 'zh-TW'
			else
				file_name = file_name
			end

			file_mo   = open( File.join( Dir.pwd, 'languages', "#{file_name}.mo" ), 'wb' )
			file_po  = open( File.join( Dir.pwd, 'languages', "#{file_name}.po" ), 'wb' )

			# Download the .mo. We're writing straight to the open file rather than buffering contents in memory
			http.request_get( "#{translation[:base_url]}/export-translations?format=mo" ) do |response|
				response.read_body do |segment|
					file_mo.write( segment )
				end
			end

			# Download the .po. We're writing straight to the open file rather than buffering contents in memory
			http.request_get( "#{translation[:base_url]}/export-translations?format=po" ) do |response|
				response.read_body do |segment|
					file_po.write( segment )
				end
			end

			file_mo.close
			file_po.close
		end

	end
end

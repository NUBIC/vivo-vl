require 'csv'
require "#{Rails.root}/lib/tasks/vivo"
include Vivo

##
# Tasks to call the VIVO SPARQL API to get data 
# which is then massaged into a format used by the 
# highcharts bar graph. 
# @see HighchartsController
namespace :publications_by_year do

  desc 'Create files for for all vivo:FacultyMembers saving the uri and name of each and save them in the tmp/vivo/faculty_members/uris.json file'
  task :uris => :environment do 
    run_all_uris_and_names_curl
  end

  desc 'Create files for the publication counts for the last 40 years and save them in the tmp/vivo/publication_counts_by_year directory'
  task :counts => :environment do
    dir = "tmp/vivo/publication_counts_by_year"
    ((Time.now.year-40)..Time.now.year).each do |year|
      FileUtils.mkdir_p(dir) unless File.exist?(dir)
      filename = "#{dir}/#{year}.json"
      File.open('publications_by_year.sparql', 'w') { |file| file.write(publications_by_year_sparql(year)) }
      %x( curl -d 'email=#{vivo_user}' -d 'password=#{password}' -d '@publications_by_year.sparql' -H 'Accept: application/sparql-results+json' 'http://localhost:8080/vivo/api/sparqlQuery' > #{filename} )
    end
  end

  def publications_by_year_sparql(year)
    "query=#{rdf_prefices} 
      SELECT (count(?pub) as ?cnt)
      WHERE {
        ?pub rdf:type bibo:Article .
        ?pub vivo:dateTimeValue ?dtv .
        ?dtv rdf:type vivo:DateTimeValue .
        ?dtv vivo:dateTime ?dt .
        FILTER (str(?dt) >= '#{year}-01-01T:00:00:00')
        FILTER (str(?dt) <= '#{year}-12-31T:00:00:00')
      }"
  end
end

# SELECT (count(?pub) as ?cnt)
# SELECT ?pub ?po_name ?ou_name ?fm_name
# WHERE {
#   ?ou rdf:type vivo:Center .
#   ?ou rdfs:label ?ou_name .
#   ?position vivo:relates ?ou .
#   ?position rdf:type vivo:Position .
#   ?position rdfs:label ?po_name .
#   ?position vivo:relates ?member .
#   ?member rdf:type vivo:FacultyMember . 
#   ?member rdfs:label ?fm_name .

#   ?authorship rdf:type vivo:Authorship .
#   ?authorship vivo:relates ?pub .
#   ?pub rdf:type bibo:Document .
#   ?authorship vivo:relates ?member .

#  FILTER (?ou_name = 'Northwestern University Clinical and Translational Sciences Institute (NUCATS)')
#  FILTER (?po_name = 'Primary')


#  ?pub vivo:dateTimeValue ?dtv .
#  ?dtv rdf:type vivo:DateTimeValue .
#  ?dtv vivo:dateTime ?dt .

#  FILTER (str(?dt) >= '2012-01-01T:00:00:00')
#  FILTER (str(?dt) <= '2012-12-31T:00:00:00')
# }


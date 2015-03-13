require 'csv'
require "#{Rails.root}/lib/tasks/vivo"
include Vivo

##
# Tasks to call the VIVO SPARQL API to get data 
# which is then massaged into a format used by the 
# highcharts pie graph. 
# @see HighchartsController
namespace :pie do

  desc 'Create files for for all vivo:FacultyMembers saving the uri and name of each and save them in the tmp/vivo/faculty_members/uris.json file'
  task :uris => :environment do 
    run_all_uris_and_names_curl
  end

  desc 'Create files for the pi, the types of documents they have published, and save them in the tmp/vivo/publication_types directory'
  task :publication_type_counts => :environment do
    vivo_uris_and_names.each do |uri, name|
      dir = "tmp/vivo/publication_types/#{uuid_from_uri(uri)}"
      publication_types.each do |type|
        FileUtils.mkdir_p(dir) unless File.exist?(dir)
        filename = "#{dir}/#{type.gsub(':', '_').downcase}.json"
        File.open('publication_type.sparql', 'w') { |file| file.write(publication_type_sparql(uri, type)) }
        %x( curl -d 'email=#{vivo_user}' -d 'password=#{password}' -d '@publication_type.sparql' -H 'Accept: application/sparql-results+json' 'http://localhost:8080/vivo/api/sparqlQuery' > #{filename} )
      end
      arr = []
      CSV.open("#{dir}/pie_data.csv", 'wb', :col_sep => ',') do |csv|
        csv << ['Publication Type', 'Count']
        publication_types.each do |type|
          file = File.read("#{dir}/#{type.gsub(':', '_').downcase}.json")
          data = JSON.parse(file)
          t = "#{type.gsub(':', '_').downcase}_count"
          val = data["results"]["bindings"].first[t]["value"]
          csv << [human_readable_publication_type(type), val] if val.to_i > 0
        end
      end
    end
  end

  desc 'Create files for the pi, the types of documents they have published, and save them in the tmp/vivo/publication_types directory'
  task :medline_category_counts => :environment do
    vivo_uris_and_names.each do |uri, name|
      dir = "tmp/vivo/medline_categories/#{uuid_from_uri(uri)}"
      medline_categories.each do |cat|
        FileUtils.mkdir_p(dir) unless File.exist?(dir)
        filename = "#{dir}/#{cat.gsub('.', '').gsub('\'', '').gsub(',', '').gsub(' ', '_').downcase}.json"
        File.open('medline_categories.sparql', 'w') { |file| file.write(medline_categories_sparql(uri, cat)) }
        %x( curl -d 'email=#{vivo_user}' -d 'password=#{password}' -d '@medline_categories.sparql' -H 'Accept: application/sparql-results+json' 'http://localhost:8080/vivo/api/sparqlQuery' > #{filename} )
      end
      arr = []
      CSV.open("#{dir}/pie_data.csv", 'wb', :col_sep => ',') do |csv|
        csv << ['Publication Type', 'Count']
        medline_categories.each do |cat|
          file = File.read("#{dir}/#{cat.gsub('.', '').gsub('\'', '').gsub(',', '').gsub(' ', '_').downcase}.json")
          data = JSON.parse(file)
          val = data["results"]["bindings"].first['cnt']["value"]
          csv << [cat.gsub(',', ''), val] if val.to_i > 0
        end
      end
    end
  end

  # ?Publication1 rdf:type vlocal:ComparativeStudy .
  # ?Publication1 rdf:type bibo:Letter .
  def publication_type_sparql(uri, publication_type)
    "query=#{rdf_prefices} 
      SELECT (count(?Publication1) as ?#{publication_type.gsub(':', '_').downcase}_count)
      WHERE {
      ?Publication1 rdf:type #{publication_type} .
      ?Authorship1 rdf:type vivo:Authorship .
      ?Authorship1 vivo:relates <#{uri}> .
      ?Authorship1 vivo:relates ?Publication1
    }"
  end

  def medline_categories_sparql(uri, medline_category)
    "query=#{rdf_prefices} 
      SELECT (count(?Publication1) as ?cnt)
      WHERE {
      ?Publication1 vlocal:medlineCategory ?medline_category .
      ?Authorship1 rdf:type vivo:Authorship .
      ?Authorship1 vivo:relates <#{uri}> .
      ?Authorship1 vivo:relates ?Publication1
      FILTER ( regex (str(?medline_category), \"#{medline_category}\", \"i\") )
    }"
  end

  def publication_types
    [
      'bibo:AcademicArticle',
      'obo:ERO_0000016',
      'fabio:Comment',
      'vlocal:ComparativeStudy',
      'vlocal:EvaluationStudy',
      'bibo:Letter',
    ]
  end

  def medline_categories
    [
      'Autobiography',
      'Bibliography',
      'Biography',
      'Introductory Journal Article', 
      'Journal Article', 
      'Classical Article', 
      'English Abstract', 
      'Historical Article', 
      'In Vitro', 
      'Meta-Analysis', 
      'Multicenter Study', 
      'Overall',
      'Addresses',
      'Lectures',
      'Clinical Trial', 
      'Clinical Trial, Phase I', 
      'Clinical Trial, Phase II', 
      'Clinical Trial, Phase III', 
      'Clinical Trial, Phase IV', 
      'Controlled Clinical Trial',
      'Editorial Article', 
      'EDITORIAL',
      'Comment',
      'Letter',
      'Clinical Conference', 
      'Congresses', 
      'Newspaper Article', 
      "Research Support, U.S. Gov't, P.H.S.",
      'Consensus Development Conference',
      'Consensus Development Conference, NIH',
      'Directory',
      'Comparative Study',
      'Evaluation Studies',
      'Clinical Guideline',
      'News',
      'Published Erratum',
      'REVIEW',
      'Video-Audio Media',
    ]
  end

  def human_readable_publication_type(type)
    case type
    when 'bibo:AcademicArticle'
      'Academic Article'
    when 'obo:ERO_0000016'
      'Clinical Trial'
    when 'fabio:Comment'
      'Comment'
    when 'bibo:Letter'
      'Letter'
    when 'vlocal:ComparativeStudy'
      'Comparative Study'
    when 'vlocal:EvaluationStudy'
      'Evaluation Study'
    else
      'Document'
    end
      
  end

end
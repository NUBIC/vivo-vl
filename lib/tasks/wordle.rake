##
# Tasks to call the VIVO SPARQL API to get data 
# which is then massaged into a format used by the 
# word cloud graph. 
# @see D3Controller
namespace :wordle do

  FILLER_WORDS = %w(the of and as to a in that with for an at not by on but or from its when this these i was is we have some into may well there our it me you what which who whom those are were be however been being has had do did doing will can isn't aren't wasn't weren't to very would also after other whose upon their could all none no us here eg how where such many more than highly annotation annotations along each both then any same only significant significantly without versus likely while later whether might particular among thus every through over thereby about they your them within should much because ie between aka either under fully most since using used if nor yet easily moreover despite does quite less her found via type review age last purpose new takes own easily problem)

  desc 'Create files for for all vivo:FacultyMembers saving the uri and name of each and save them in the tmp/vivo/faculty_members/uris.json file'
  task :uris => :environment do 
    run_all_uris_and_names_curl
  end

  desc 'Create files for all the words used in publications per author and save them in the tmp/vivo/wordle directory'
  task :get_words => :environment do 
    vivo_uris_and_names.each do |uri, name|
      run_wordle_curl(uri)
    end
  end

  ##
  # Run curl to vivo/api/sparqlQuery
  # and output it to a file in the tmp/vivo/wordle directory
  # cf. https://wiki.duraspace.org/display/VIVO/The+SPARQL+Query+API
  # @param[String] uri for the vivo:FacultyMember
  def run_wordle_curl(uri)
    filename = "tmp/vivo/wordle/#{uuid_from_uri(uri)}.json"
    File.open('wordle.sparql', 'w') { |file| file.write(wordle_sparql(uri)) }
    %x( curl -d 'email=#{vivo_user}' -d 'password=#{password}' -d '@wordle.sparql' -H 'Accept: application/sparql-results+json' 'http://localhost:8080/vivo/api/sparqlQuery' > #{filename} )
  end

  desc 'Put the data we got from the get_words task into the format we want and save it into the tmp/vivo/wordle_data directory'
  task :data => :environment do 
    # { "word":"WORD", "frequency":1, "the_type":"Abstract" }
    Wordle = Struct.new(:word, :frequency, :the_type)
    vivo_uris_and_names.each do |uri, name|
      filename = "#{Rails.root}/tmp/vivo/wordle_data/#{uuid_from_uri(uri)}.json"
      next if File.exist?(filename)
      words = []
      get_wordle_data(uri).each do |w|
        title = w['title']['value'].downcase
        title.split(/\W+/).each do |word|
          words << word unless FILLER_WORDS.include?(word) || word.length < 3 || word.to_i > 0
        end
      end
      hsh = {}
      words.each do |word|
        if hsh[word] 
          hsh[word].frequency += 1
        else
          hsh[word] = Wordle.new(word, 1, 'Abstract')
        end
      end
      json = hsh.values.as_json.to_s.gsub('=>', ':')
      File.open(filename, 'w') { |file| file.write(json) }
    end
  end

  ## 
  # Read the data from the wordle file
  # @param[String] uri for the vivo:FacultyMember
  # @return[Array<String>]
  def get_wordle_data(uri)
    filename = "#{Rails.root}/tmp/vivo/wordle/#{uuid_from_uri(uri)}.json"
    file = File.read(filename)
    data = JSON.parse(file)
    data["results"]["bindings"]
  end

  ##
  # SPARQL query to get the title from the associated bibo:Documents
  # for the given author
  # @param[String] uri for the vivo:FacultyMember
  # @return[String]
  def wordle_sparql(uri)
    # SELECT ?publication ?title ?abstract
    # OPTIONAL { ?publication bibo:abstract ?abstract } .
    "query=#{rdf_prefices} 
    SELECT ?publication ?title 
    WHERE
    {
      ?authorship rdf:type vivo:Authorship .
      ?authorship vivo:relates <#{uri}> .
      ?publication rdf:type bibo:Document .
      ?publication vivo:relatedBy ?authorship .
      ?publication rdfs:label ?title .
    }
    "
  end

end


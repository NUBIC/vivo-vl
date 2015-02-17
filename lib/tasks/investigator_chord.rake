require "#{Rails.root}/lib/tasks/vivo"
include Vivo

##
# Tasks to call the VIVO SPARQL API to get data 
# which is then massaged into a format used by the 
# d3 chord graph. 
# @see D3Controller
namespace :investigator_chord do
 
  desc 'Create files for for all vivo:FacultyMembers saving the uri and name of each and save them in the tmp/vivo/faculty_members/uris.json file'
  task :uris => :environment do 
    run_all_uris_and_names_curl
  end

  desc 'Create the files for the pi and coauthors and save them in the tmp/vivo/coauthors directory'
  task :coauthors => :environment do 
    vivo_uris_and_names.each do |uri, name|
      run_coauthor_curl(uri)
      get_coauthor_array(uri).each do |coauthor|
        # We do need to know what we are getting back from the coauthor_sparql query below
        run_coauthor_curl(coauthor["Coauthor"]["value"])
      end
    end
  end

  desc 'Almost the same as above but get the publication count and save it into the tmp/vivo/publication_counts directory'
  task :publication_counts => :environment do 
    vivo_uris_and_names.each do |uri, name|
      run_publication_count_curl(uri)
      get_coauthor_array(uri).each do |coauthor| 
        run_publication_count_curl(coauthor["Coauthor"]["value"])
      end
    end
  end

  ##
  # @see build_chord_data_array
  desc 'Put the data we got from coauthors and publication_counts tasks into the format we want and save it into the tmp/vivo/chord_data directory'
  task :chord_data => :environment do 
    vivo_uris_and_names.each do |uri, name|
      filename = "#{Rails.root}/tmp/vivo/chord_data/#{uuid_from_uri(uri)}.json"
      next if File.exist?(filename)
      # Here we also would like the name of the author
      coauthors = build_chord_data_array(uri, name)
      json = coauthors.as_json.to_s.gsub('=>', ':')
      File.open(filename, 'w') { |file| file.write(json) }
    end
  end

  ##
  # This method takes the data from the coauthors and publication_counts tasks
  # and builds the data needed for the chord graph 
  # This returns an array of hashes:
  # [ { name: AUTHOR_NAME, size: #_OF_PUBLICATIONS, imports: [ COAUTHOR_NAMES ] } ]
  # @return[Array<Hash>]
  def build_chord_data_array(uri, pi_name)
    coauthors = []
    coauthor_array = get_coauthor_array(uri)
    # put the pi in question as the first person in the coauthors array
    pi_imports = imports(coauthor_array)
    coauthors << {name: pi_name, size: pub_count(uri), imports: pi_imports}
    # then build the same hash for each coauthor 
    coauthor_array.each do |coauthor|
      name = coauthor["Coauthor_name"]["value"]
      uri  = coauthor["Coauthor"]["value"]
      pub_cnt = pub_count(uri)
      co_imports = get_coauthor_imports(uri)
      coauthors << {name: name, size: pub_cnt, imports: (pi_imports & co_imports)}
    end
    coauthors
  end

  ##
  # SPARQL query to get the Coauthor URI, Coauthor Name, and PI Name 
  # @param[String] uri for the vivo:FacultyMember
  # @return[String]
  def coauthor_sparql(uri)
    "query=#{rdf_prefices} SELECT distinct ?Coauthor ?Coauthor_name ?PI_name 
      WHERE {
        ?Authorship1 rdf:type vivo:Authorship .
        ?Authorship1 vivo:relates <#{uri}> .
        ?Authorship1 vivo:relates ?Document1 .
        ?Document1 rdf:type bibo:Document .
        ?Document1 vivo:relatedBy ?Authorship2 .
        ?Authorship2 rdf:type vivo:Authorship .
        ?Coauthor rdf:type vivo:FacultyMember .
        ?Coauthor vivo:relatedBy ?Authorship2 .
        ?Coauthor rdfs:label ?Coauthor_name .
        <#{uri}> rdfs:label ?PI_name .
      FILTER (!(?Authorship1=?Authorship2))
    }"
  end

  ##
  # SPARQL query to determine the number of shared publications between two coauthors
  # @param[String] uri1 for one of the vivo:FacultyMember authors
  # @param[String] uri2 for the other vivo:FacultyMember author
  # @return[String]
  def coauthor_count_sparql(uri1, uri2)
    "query=#{rdf_prefices} SELECT (count(?Document1) as ?cnt)
      WHERE {
        ?Authorship1 rdf:type vivo:Authorship .
        ?Authorship1 vivo:relates <#{uri1}> .
        ?Authorship1 vivo:relates ?Document1 .
        ?Document1 rdf:type bibo:Document .
        ?Document1 vivo:relatedBy ?Authorship2 .
        ?Authorship2 rdf:type vivo:Authorship .
        ?Authorship2 vivo:relates <#{uri2}>
    }"
  end

  ##
  # SPARQL query to get the number of publications for this person in VIVO
  # @param[String] uri for the vivo:FacultyMember
  # @return[String]
  def publication_count_sparql(uri)
    "query=#{rdf_prefices} SELECT (count(?Authorship1) as ?cnt)
    WHERE {
    ?Authorship1 rdf:type vivo:Authorship .
    ?Authorship1 vivo:relates <#{uri}>
    }"
  end

  ##
  # Run curl to vivo/api/sparqlQuery
  # and output it to a file in the tmp/vivo/coauthors directory
  # cf. https://wiki.duraspace.org/display/VIVO/The+SPARQL+Query+API
  # @param[String] uri for the vivo:FacultyMember
  def run_coauthor_curl(uri)
    filename = "tmp/vivo/coauthors/#{uuid_from_uri(uri)}.json"
    return if File.exist?(filename)    
    File.open('coauthor.sparql', 'w') { |file| file.write(coauthor_sparql(uri)) }
    %x( curl -d 'email=#{vivo_user}' -d 'password=#{password}' -d '@coauthor.sparql' -H 'Accept: application/sparql-results+json' 'http://localhost:8080/vivo/api/sparqlQuery' > #{filename} )
  end

  ##
  # Run curl to vivo/api/sparqlQuery
  # and output it to a file in the tmp/vivo/publication_counts directory
  # cf. https://wiki.duraspace.org/display/VIVO/The+SPARQL+Query+API
  # @param[String] uri for the vivo:FacultyMember
  def run_publication_count_curl(uri)
    filename = "tmp/vivo/publication_counts/#{uuid_from_uri(uri)}.json"
    return if File.exist?(filename)
    File.open('publication_count.sparql', 'w') { |file| file.write(publication_count_sparql(uri)) }
    %x( curl -d 'email=#{vivo_user}' -d 'password=#{password}' -d '@publication_count.sparql' -H 'Accept: application/sparql-results+json' 'http://localhost:8080/vivo/api/sparqlQuery' > #{filename} )
  end

  ##
  # Get the imports array for the given author
  # @param[String] uri for the vivo:FacultyMember
  # @return[Array]
  def get_coauthor_imports(uri)
    imports(get_coauthor_array(uri))
  end

  ## 
  # Read the data from the coauthors file
  # @param[String] uri for the vivo:FacultyMember
  # @return[Array]
  def get_coauthor_array(uri)
    filename = "#{Rails.root}/tmp/vivo/coauthors/#{uuid_from_uri(uri)}.json"
    file = File.read(filename)
    data = JSON.parse(file)
    data["results"]["bindings"]
  end

  ##
  # Create an array of coauthor name
  # @param[Array<Hash>]
  # @return[Array<String>]
  def imports(coauthor_array)
    imports = []
    coauthor_array.each { |c| imports << c["Coauthor_name"]["value"] }
    imports
  end

  ## 
  # Read the data from the publication_counts file
  # @param[String] uri for the vivo:FacultyMember
  # @return[String]
  def pub_count(uri)
    filename = "#{Rails.root}/tmp/vivo/publication_counts/#{uuid_from_uri(uri)}.json"
    file = File.read(filename)
    data = JSON.parse(file)
    data["results"]["bindings"].first['cnt']['value']
  end

end

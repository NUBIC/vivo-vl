##
# Methods shared among the rake tasks used to build
# data used in the UI.
module Vivo

  def sparql_query_api_url
    'http://localhost:8080/vivo/api/sparqlQuery'
  end

  ##
  # Set this to your instiution's namespace
  # @see uuid_from_uri(uri)
  def vivo_namespace
    'http://vivo.northwestern.edu/individual/n'
  end

  ##
  # Set this to the username/email of the vivo user who can
  # run queries through the SPARQL API
  def vivo_user
    'vivo_root@school.edu'
  end

  ##
  # Password for the vivo_user
  def password
    'pwd'
  end

  ##
  # Strip the vivo_namespace from the given uri param
  # to get a unique identifier from the string 
  def uuid_from_uri(uri)
    uri.gsub(vivo_namespace, '')
  end

  ##
  # Run the curl command we learned from Jim and the wiki to make a call to vivo/api/sparqlQuery
  # and output it to a file in the tmp/vivo/faculty_members directory
  def run_all_uris_and_names_curl
    File.open('uris.sparql', 'w') { |file| file.write(uris_sparql) }
    %x( curl -d 'email=#{vivo_user}' -d 'password=#{password}' -d '@uris.sparql' -H 'Accept: application/sparql-results+json' '#{sparql_query_api_url}' > tmp/vivo/faculty_members/uris.json )
  end

  ##
  # SPARQL to get uris and names for all vivo:FacultyMembers
  def uris_sparql
    "query=#{rdf_prefices} SELECT distinct ?faculty_member ?name
    WHERE {
      ?faculty_member rdf:type vivo:FacultyMember .
      ?faculty_member rdfs:label ?name .
    }"
  end

  ##
  # An array of investigator unique identifiers and names
  # The uuids can be used to build the VIVO URI. 
  # Names are used when building the data used by the graphs.
  #  
  #   SELECT distinct ?uri ?name 
  #   WHERE {
  #     ?uri rdf:type vivo:FacultyMember .
  #     ?uri rdfs:label ?name .
  #   } 
  #
  # @see vivo_uri
  def vivo_uris_and_names
    arr = []
    filename = "#{Rails.root}/tmp/vivo/faculty_members/uris.json"
    file = File.read(filename)
    data = JSON.parse(file)
    data["results"]["bindings"].each do |result|
      uri  = result['faculty_member']['value']
      name = result['name']['value']
      arr << [uri, name]
    end
    arr
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
  # Read the data from the publication_counts file
  # @param[String] uri for the vivo:FacultyMember
  # @return[String]
  def pub_count(uri)
    filename = "#{Rails.root}/tmp/vivo/publication_counts/#{uuid_from_uri(uri)}.json"
    file = File.read(filename)
    data = JSON.parse(file)
    data["results"]["bindings"].first['cnt']['value']
  end

  ## 
  # Read the data from the coauthor_counts file
  # @param[String] uri for the vivo:FacultyMember
  # @return[String]
  def shared_pub_count(uri1, uri2)
    filename = "#{Rails.root}/tmp/vivo/coauthor_counts/#{uuid_from_uri(uri1)}_#{uuid_from_uri(uri2)}.json"
    file = File.read(filename)
    data = JSON.parse(file)
    data["results"]["bindings"].first['cnt']['value']
  end

  ##
  # RDF Prefices needed to run the SPARQL queries below
  # @see coauthor_sparql
  # @see publication_count_sparql
  def rdf_prefices
    "PREFIX rdf:     <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
    PREFIX rdfs:     <http://www.w3.org/2000/01/rdf-schema#>
    PREFIX vitro:    <http://vitro.mannlib.cornell.edu/ns/vitro/0.7#>
    PREFIX bibo:     <http://purl.org/ontology/bibo/>
    PREFIX foaf:     <http://xmlns.com/foaf/0.1/>
    PREFIX vcard:    <http://www.w3.org/2006/vcard/ns#>
    PREFIX fabio:    <http://purl.org/spar/fabio/>
    PREFIX obo:      <http://purl.obolibrary.org/obo/>
    PREFIX vivo:     <http://vivoweb.org/ontology/core#>
    PREFIX vlocal:   <http://vivo.northwestern.edu/ontology/vlocal#>
    "
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
end
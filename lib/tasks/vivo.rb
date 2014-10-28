##
# Methods shared among the rake tasks used to build
# data used in the UI.
module Vivo
  
  ##
  # Set this to your instiution's namespace
  # @see uuid_from_uri(uri)
  def vivo_namespace
    'http://vivo.northwestern.edu/individual/'
  end

  ##
  # Set this to the username/email of the vivo user who can
  # run queries through the SPARQL API
  def vivo_user
    'vivo_root@northwestern.edu'
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
    %x( curl -d 'email=#{vivo_user}' -d 'password=#{password}' -d '@uris.sparql' -H 'Accept: application/sparql-results+json' 'http://localhost:8080/vivo/api/sparqlQuery' > tmp/vivo/faculty_members/uris.json )
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
    PREFIX vivo:     <http://vivoweb.org/ontology/core#>"
  end
end
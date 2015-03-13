require "#{Rails.root}/lib/tasks/vivo"
include Vivo

##
# Tasks to call the VIVO SPARQL API to get data 
# which is then massaged into a format used by
# cytoscapeweb - http://cytoscapeweb.cytoscape.org/
# @see CytoscapeController
namespace :cytoscape do

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
  task :coauthor_counts => :environment do 
    vivo_uris_and_names.each do |uri, name|
      get_coauthor_array(uri).each do |coauthor| 
        run_coauthor_count_curl(uri, coauthor["Coauthor"]["value"])
      end
    end
  end

  ##
  # @see build_chord_data_array
  desc 'Put the data we got from coauthors and publication_counts tasks into the format we want and save it into the tmp/vivo/network_data directory'
  task :network_data => :environment do 
    vivo_uris_and_names.each do |uri, name|
      filename = "#{Rails.root}/tmp/vivo/network_data/#{uuid_from_uri(uri)}.json"
      next if File.exist?(filename)

      # Here we also would like the name of the author
      network = build_network_data(uri, name)

      json = network.as_json.to_s.gsub('=>', ':')
      File.open(filename, 'w') { |file| file.write(json) }
    end
  end

  ##
  # This method takes the data from the coauthors and coauthor_counts tasks
  # and builds the data needed for the cytoscape network
  # @return[Array<Hash>]
  def build_network_data(uri, name, node_array=[], edge_array=[])
    node_array = investigator_nodes(uri, name, node_array)
    edge_array = investigator_edges(uri, node_array, edge_array)
    { :dataSchema => cytoscape_schema, :data => { :nodes => node_array, :edges => edge_array } }
  end

  ##
  # Simply send to cytoscape the layout of the 
  # data that will be sent for the nodes and edges
  def cytoscape_schema
    {
      :nodes => [
        {:name => "label", :type => "string"},
        {:name => "element_type", :type => "string"},
        {:name => "tooltiptext", :type => "string"},
        {:name => "weight", :type => "number"},
        {:name => "depth", :type => "number"},
        {:name => "mass", :type => "long"}
      ],
      :edges => [
        {:name => "label", :type => "string"},
        {:name => "element_type", :type => "string"},
        {:name => "tooltiptext", :type => "string"},
        {:name => "weight", :type => "long"},
        {:name => "directed", :type => "boolean", :defValue => true}
      ]
    }
  end

  # {"id":"1751","element_type":"Investigator","label":"Warren Kibbe","weight":275,"mass":275,"depth":0,"tooltiptext":"Publications: 50"}
  def investigator_nodes(uri, name, node_array)
    nodes = []
    coauthor_array = get_coauthor_array(uri)
    # put the pi in question as the first person in the nodes array
    coauthor_pub_count = coauthor_array.inject(0) { |result, coauthor| result + pub_count(coauthor["Coauthor"]["value"]).to_i }
    pub_count = pub_count(uri).to_i
    tooltip = "Publications: #{pub_count}"
    nodes << cytoscape_investigator_node_hash(uri, name, (pub_count + coauthor_pub_count), tooltip, 0)
    # then build the same hash for each coauthor 

    coauthor_array.each do |coauthor|
      name = coauthor["Coauthor_name"]["value"]
      uri  = coauthor["Coauthor"]["value"]
      pub_count = pub_count(uri)
      tooltip = "Publications: #{pub_count}"
      nodes << cytoscape_investigator_node_hash(uri, name, pub_count.to_i, tooltip, 1)
    end
    nodes
  end

  def cytoscape_investigator_node_hash(uri, name, pub_count, tooltip, depth)
    {
      :id => uuid_from_uri(uri),
      :element_type => 'Investigator',
      :label => name,
      :depth => depth,
      :weight => pub_count,
      :mass => pub_count,
      :tooltiptext => tooltip
    }
  end

  # {"id":"0","label":"10","tooltiptext":"10 publications","source":"1751","target":"557","weight":10,"element_type":"Publication"}
  def investigator_edges(uri, node_array, edge_array)
    edges = []
    coauthor_array = get_coauthor_array(uri)
    coauthor_array.each_with_index do |coauthor, idx|
      coauthor_uri  = coauthor["Coauthor"]["value"]
      edges << cytoscape_edge_hash(idx, uuid_from_uri(uri), uuid_from_uri(coauthor_uri), shared_pub_count(uri, coauthor_uri))
    end
    edges
  end


  def cytoscape_edge_hash(edge_index, source_index, target_index, shared_pub_count)
    {
      :id => edge_index.to_s,
      :element_type => 'Publication',
      :label => shared_pub_count.to_s,
      :tooltiptext => "#{shared_pub_count} shared publications",
      :source => source_index,
      :target => target_index,
      :weight => shared_pub_count.to_i
    }
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
  def run_coauthor_count_curl(uri1, uri2)
    filename = "tmp/vivo/coauthor_counts/#{uuid_from_uri(uri1)}_#{uuid_from_uri(uri2)}.json"
    return if File.exist?(filename)
    File.open('coauthor_count.sparql', 'w') { |file| file.write(coauthor_count_sparql(uri1, uri2)) }
    %x( curl -d 'email=#{vivo_user}' -d 'password=#{password}' -d '@coauthor_count.sparql' -H 'Accept: application/sparql-results+json' 'http://localhost:8080/vivo/api/sparqlQuery' > #{filename} )
  end

end
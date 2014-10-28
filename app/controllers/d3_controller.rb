##
# Controller for examples of data visualizations using the
# d3 (Data-Driven Documents) family of javascript libraries
# @see http://d3js.org
class D3Controller < ApplicationController

  before_filter :set_javascripts

  ##
  # Easy way to get the name of the selected faculty member
  # as it is in the chord_data data file for the chosen person.
  # Returns nil if no file exists.
  # @return[String]
  def name
    value = nil
    filename = "#{Rails.root}/tmp/vivo/chord_data/#{params[:id]}.json"
    if File.exist?(filename)
      file = File.read(filename)
      data = JSON.parse(file)
      value = data.first['name']
    end
    value
  end

  ##
  # Chord Diagram showing the relationship of investigator collaborations
  # through the vivo:Authorship records
  # @see http://bl.ocks.org/mbostock/4062006
  def investigator_chord
    set_json_callback("../d3/#{params[:id]}/investigator_chord_data.js")
    set_title('Chord Diagram showing investigator collaborations through publications')

    respond_to do |format|
      format.html { render layout: 'vivo' }
      format.json { render layout: false, text: '' }
    end
  end

  ##
  # Return data created for the selected person as created in the 
  # chord_data rake task.
  # @see lib/tasks/investigator_chord.rake#chord_data task
  def investigator_chord_data
    file = "#{Rails.root}/tmp/vivo/chord_data/#{params[:id]}.json"
    respond_to do |format|
      format.json { send_file file, :type => 'text/json', :disposition => 'inline' }
      format.js   { send_file file, :type => 'text/json', :disposition => 'inline' }
    end
  end

  ##
  # Page to display a word cloud based on the publication data
  # we collected from associated bibo:Document records. 
  # Based on Jason Davies' Word Cloud
  # @see https://github.com/jasondavies/d3-cloud
  # @see http://www.jasondavies.com/wordcloud
  def wordle
    set_title('Word cloud (Wordle) display of abstracts')
    set_json_callback("../d3/#{params[:id]}/wordle_data.js")
    respond_to do |format|
      format.html { render layout: 'vivo' }
      format.json { render layout: false, text: '' }
    end
  end

  ##
  # Return data created for the selected person as created in the 
  # wordle data rake task.
  # @see lib/tasks/wordle.rake#data task
  def wordle_data
    if params[:id]
      file = "#{Rails.root}/tmp/vivo/wordle_data/#{params[:id]}.json"
    end
    respond_to do |format|
      format.json { send_file file, :type => 'text/json', :disposition => 'inline' }
      format.js   { send_file file, :type => 'text/json', :disposition => 'inline' }
    end
  end

  ##
  # Set the @json_callback variable
  # to the path of the data for the graph
  def set_json_callback(path)
    @json_callback = path
  end
  private :set_json_callback

  ##
  # Set the @title variable for the text on the page.
  # This method appends the name of the person if it exists
  # @see name
  def set_title(title)
    title << " for #{name}" if name
    @title = title
  end
  private :set_title

  ##
  # Set the @javascripts variable to the javascript
  # files used by the d3 pages
  def set_javascripts
    @javascripts = %w( d3/d3.js d3/d3.layout.js d3/package.js d3/d3.layout.cloud.js d3/jsonp.js d3/highlight.min.js )
  end
  private :set_javascripts

end

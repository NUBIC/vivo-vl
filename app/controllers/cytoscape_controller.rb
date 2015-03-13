##
# Controller for examples of data visualizations using the
# cytoscapeweb library 
# @see http://cytoscapeweb.cytoscape.org/
class CytoscapeController < ApplicationController

  before_filter :set_javascripts

  ##
  # Co-author network graph
  # @see http://www.highcharts.com/demo/pie-basic
  def network
    @dataurl = "/cytoscape/#{params[:id]}/network_data.js"
  end

  ##
  # Return data created for the selected person as created in the 
  # cytoscape_network_data rake task.
  def network_data
    file = "#{Rails.root}/tmp/vivo/network_data/#{params[:id]}.json"
    respond_to do |format|
      format.json { send_file file, :type => 'text/json', :disposition => 'inline' }
      format.js   { send_file file, :type => 'text/json', :disposition => 'inline' }
    end
  end


  ##
  # Set the @javascripts variable to the javascript
  # files used by the cytoscape pages
  def set_javascripts
    @javascripts = %w( cytoscape/cytoscapeweb-defaults.js cytoscape/cytoscapeweb-file.js cytoscape/cytoscapeweb.js cytoscape/flash_detect_min.js cytoscape/home.js cytoscape/jquery-1.8.3.js cytoscape/jquery-ui.min.js cytoscape/jquery.cytoscape.web.js cytoscape/json2.js cytoscape/AC_OETags.js )
  end
  private :set_javascripts

end

##
# Controller for examples of data visualizations using the
# highcharts javascript library
# @see http://www.highcharts.com
class HighchartsController < ApplicationController

  ##
  # Pie chart showing the types of investigator publications
  # @see http://www.highcharts.com/demo/pie-basic
  def publication_types_pie_chart
  end

  ##
  # Return data created for the selected person as created in the 
  # publication_type_counts rake task.
  # @see lib/tasks/pie.rake#publication_type_counts task
  def publication_types_pie_chart_data
    file = "#{Rails.root}/tmp/vivo/publication_types/#{params[:id]}/pie_data.csv"
    respond_to do |format|
      format.csv { send_file file, :type => 'text/csv', :disposition => 'inline' }
    end
  end

end
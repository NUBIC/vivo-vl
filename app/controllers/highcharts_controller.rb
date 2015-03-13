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

  ##
  # Pie chart showing the types of investigator publications
  # @see http://www.highcharts.com/demo/pie-basic
  def medline_categories_pie_chart
  end

  ##
  # Return data created for the selected person as created in the 
  # medline_category_counts rake task.
  # @see lib/tasks/pie.rake#medline_category_counts task
  def medline_categories_pie_chart_data
    file = "#{Rails.root}/tmp/vivo/medline_categories/#{params[:id]}/pie_data.csv"
    respond_to do |format|
      format.csv { send_file file, :type => 'text/csv', :disposition => 'inline' }
    end
  end


  def publications_by_year
    @seriesData = publications_by_year_data
  end

  def publications_by_year_data
    dir = "#{Rails.root}/tmp/vivo/publication_counts_by_year"
    series_data = []
    year_range.each do |year|
      file = File.read("#{dir}/#{year}.json")
      data = JSON.parse(file)
      series_data << { "name" => year, "data" => [data["results"]["bindings"].first['cnt']['value']] }
    end
    series_data.to_json.html_safe.gsub("\"", "")
  end

  def year_range
    (Time.now.year-40)..Time.now.year
  end

end
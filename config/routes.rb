Rails.application.routes.draw do

  match 'd3/:id/investigator_chord' => 'd3#investigator_chord', as: :d3_investigator_chord, via: :get
  match 'd3/:id/investigator_chord_data.js' => 'd3#investigator_chord_data', as: :d3_investigator_chord_data, via: :get

  match 'd3/:id/wordle' => 'd3#wordle', as: :d3_wordle, via: :get
  match 'd3/:id/wordle_data.js' => 'd3#wordle_data', as: :d3_wordle_data, via: :get

  match 'highcharts/:id/publication_types_pie_chart' => 'highcharts#publication_types_pie_chart', as: :publication_types_pie_chart, via: :get
  match 'highcharts/:id/publication_types_pie_chart_data' => 'highcharts#publication_types_pie_chart_data', as: :publication_types_pie_chart_data, via: :get

  match 'highcharts/:id/medline_categories_pie_chart' => 'highcharts#medline_categories_pie_chart', as: :medline_categories_pie_chart, via: :get
  match 'highcharts/:id/medline_categories_pie_chart_data' => 'highcharts#medline_categories_pie_chart_data', as: :medline_categories_pie_chart_data, via: :get

  match 'highcharts/publications_by_year' => 'highcharts#publications_by_year', as: :publications_by_year, via: :get
  match 'highcharts/publications_by_year_data' => 'highcharts#publications_by_year_data', as: :publications_by_year_data, via: :get

  match 'cytoscape/:id/network' => 'cytoscape#network', as: :cytoscape_network, via: :get
  match 'cytoscape/:id/network_data.js' => 'cytoscape#network_data', as: :cytoscape_network_data, via: :get

end

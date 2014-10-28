Rails.application.routes.draw do

  # The page for the chord diagram
  match 'd3/:id/investigator_chord' => 'd3#investigator_chord', as: :d3_investigator_chord, via: :get
  # For chord graph data obtained from the tasks in vivo.rake
  match 'd3/:id/investigator_chord_data.js' => 'd3#investigator_chord_data', as: :d3_investigator_chord_data, via: :get

  # The page for the word cloud
  match 'd3/:id/wordle' => 'd3#wordle', as: :d3_wordle, via: :get
  # For wordle data obtained from the tasks in vivo.rake
  match 'd3/:id/wordle_data.js' => 'd3#wordle_data', as: :d3_wordle_data, via: :get
end

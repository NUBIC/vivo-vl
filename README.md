## VIVO-VL (VIVO - Visualization Library) 

---

### Overview

This is a simple [Ruby on Rails][ror] application to show examples of visualizations 
that are created with data from VIVO. 

As this is an out-of-the-box [Ruby on Rails][ror] application, there is a database
associated with this application, but it is not used. It must be created however. 
If the database does not exist, the application will show a page describing the 
steps needed to create the database.

We use [PostgreSQL][postgresql] as a database but you can use any. Simply update the 
config/database.yml file as described in the [Rails Guides][db_guide].

Most of these visualizations come from [LatticeGrid][latticegrid].

#### Chord Diagram

An example of a Chord Diagram showing the relationship of investigator collaborations
through the vivo:Authorship records. Based on [Mike Bostock's Chord Diagram][d3_chord]. 

#### Word Cloud (Wordle)

An example of a Word Cloud showing the frequency of words used in bibo:Documents
associated with an Author. Based on [Jason Davies' Word Cloud][d3_wordle].

#### Pie Chart

Using the different classes of Publications, here we show the percentage of publication
types by author. Based on [Highcharts Pie Demo][highcharts_pie_demo].

#### Publications By Year

Simple Bar Chart created using [Highcharts][highcharts] showing the number of publications for each year.

#### Cytoscape

Similar to the Chord Diagram, but showing author relationships using the [Cytoscape Web][cytoscape_web] library.

---

### Data

The data used by these graphs is pulled from VIVO through the [SPARQL API][sparql_api].

Look into the *.rake files for the SPARQL queries used, the data received, and how
the data is massaged into formats used by the data diagrams.

#### Chord Diagram

There are four (4) rake tasks to be run to get the chord diagram data

1. rake investigator_chord:uris
2. rake investigator_chord:coauthors
3. rake investigator_chord:publication_counts
4. rake investigator_chord:chord_data

These tasks and descriptions of what they do are in the 
lib/tasks/investigator_chord.rake file.

#### Word Cloud (Wordle)

There are three (3) rake tasks to be run to get the chord diagram data

1. rake wordle:uris
2. rake wordle:get_words
3. rake wordle:data

These tasks and descriptions of what they do are in the 
lib/tasks/wordle.rake file.

#### Pie Chart

There are two (2) rake tasks to be run to get the pie chart data

1. rake pie:uris
2. rake pie:publication_type_counts

These tasks and descriptions of what they do are in the 
lib/tasks/pie.rake file.

#### Publications By Year

There is one (1) rake task to be run to create the publication by year data

1. rake publications_by_year:count

These tasks and descriptions of what they do are in the 
lib/tasks/publications_by_year.rake file.

#### Cytoscape

There are four (4) rake tasks to be run to create the cytoscape radial graph data

1. rake cytoscape:uris
2. rake cytoscape:coauthors
3. rake cytoscape:coauthor_counts
4. rake cytoscape:network_data

These tasks and descriptions of what they do are in the 
lib/tasks/cytoscape.rake file.

---

### UI

There are three (3) types of files touched in order to render a page.

#### Routes

All routes are defined in the config/routes.rb file. 

There are generally two routes per data diagram - one to the page that 
renders the diagram and one to the data used to create the diagram.

#### Controllers

For organizational purposes, I have created a Controller class for 
each distinct visualization library used. For example, all diagrams
using the d3js.org libraries are in the D3Controller.

#### Views

Here is perhaps the most interesting part of this project
where we actually use the visualization libraries to render the page.

---


[ror]: http://rubyonrails.org/
[d3_chord]: http://bl.ocks.org/mbostock/4062006
[d3_wordle]: http://www.jasondavies.com/wordcloud
[postgresql]: http://www.postgresql.org
[db_guide]: http://edgeguides.rubyonrails.org/configuring.html#configuring-a-database
[latticegrid]: https://github.com/NUBIC/LatticeGrid
[sparql_api]: https://wiki.duraspace.org/display/VIVO/The+SPARQL+Query+API
[highcharts_pie_demo]: http://www.highcharts.com/demo/pie-basic
[highcharts]: http://www.highcharts.com/
[cytoscape_web]: http://cytoscapeweb.cytoscape.org
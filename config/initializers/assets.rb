# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
# Rails.application.config.assets.precompile += %w( search.js )

d3_js = %w( d3/d3.js d3/d3.layout.js d3/package.js d3/d3.layout.cloud.js d3/jsonp.js d3/highlight.min.js )
Rails.application.config.assets.precompile += d3_js
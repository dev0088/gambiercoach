# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path
# Add Yarn node_modules folder to the asset load path.
# Rails.application.config.assets.paths << Rails.root.join('node_modules')

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in the app/assets
# folder are already added.
# Rails.application.config.assets.precompile += %w( admin.js admin.css )
# Rails.application.config.assets.precompile += %w(prototype.js)
# Rails.application.config.assets.precompile += %w(niftycube.js)
# Rails.application.config.assets.precompile += %w(rico_corner.js)
# Rails.application.config.assets.precompile += %w(ajax_scaffold.js)
# Rails.application.config.assets.precompile += %w( transport_session.js )
# Add folder with webpack generated assets to assets.paths
Rails.application.config.assets.paths << Rails.root.join("app", "assets")
Rails.application.config.assets.paths << Rails.root.join("vendor")
Rails.application.config.assets.precompile += ["application.js", "application.css"]
Rails.application.config.assets.precompile += %w( checkout.js )

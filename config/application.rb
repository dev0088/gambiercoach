require_relative 'boot'

require 'rails/all'

require File.expand_path('../../lib/user_library', __FILE__)
require File.expand_path('../../lib/admin_library', __FILE__)
require File.expand_path('../../lib/utility_methods', __FILE__)
require File.expand_path('../../lib/active_record_errors_ext', __FILE__)
# require File.expand_path('../../lib/ssl_requirement', __FILE__)
# require File.expand_path('../../lib/ajax_scaffold', __FILE__)

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Kenyon
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1
    config.autoload_paths << Rails.root.join("lib")
    config.eager_load_paths << Rails.root.join("lib")
		config.action_mailer.default_url_options = { host: 'www.gambiercoach.com/' }
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
  end
end

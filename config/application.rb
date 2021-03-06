require File.expand_path('../boot', __FILE__)

require 'rails/all'
#TODO remove when updated to Rails 3.1 or greater
#require 'lib/ext-rails/active_record_association_collection' if Rails.version =~ /^3\.0/

#TODO remove once slim or rails is updated
#require 'lib/ext-rails/actionview_cachehelper'

# If you have a Gemfile, require the gems listed there, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env) if defined?(Bundler)

module Meegoqa
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    # config.autoload_paths += %W(#{config.root}/extras)
    config.autoload_paths += %W(#{config.root}/app/models/validation)
    config.autoload_paths += %W(#{config.root}/app/middleware/)

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # JavaScript files you want as :defaults (application.js is always included).
    config.action_view.javascript_expansions[:defaults] = %w()

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    # Observers for automatic exports. Needs server definition in config/exporter_config.yml
    config.active_record.observers = :meego_test_session_observer, :meego_test_case_observer

    # Disable the asset pipeline
    config.assets.enabled = true
    config.assets.precompile += [
        'index.js',
        'report_group.js',
        'comparison_show.js',
        'report_add.js',
        'report_view.js',
        'report_print.js',
        'report_edit.js',
        'bluff/excanvas.js'
    ]

    # Since Rails 3 rescuing routing errors is odd/not working. We can however
    # set the exceptions app to our own router and route /404 from there.
    # http://blog.plataformatec.com.br/2012/01/my-five-favorite-hidden-features-in-rails-3-2/
    config.exceptions_app = self.routes
  end
end

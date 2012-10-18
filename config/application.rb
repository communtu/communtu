require File.expand_path('../boot', __FILE__)

require 'rails/all'

#SETTINGS = YAML.load_file("#{Rails.root.to_s}/config/settings.yml")

if defined?(Bundler)
  # If you precompile assets before deploying to production, use this line
  Bundler.require(*Rails.groups(:assets => %w(development test)))
  # If you want your assets lazily compiled in production, use this line
  Bundler.require(:default, :assets, Rails.env)
end

module Communtu
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    #config.action_controller.session = {
    #:key     => '_communtu_session', # was session_key, changed for 2.3.8
    #:secret          => '367e4806af33b2cd7ddc839f908a7ed6844a3b369ce46724a3c419a633c1c68d612692d3f441ba2b31158e167c4bb5c81a5be173e83a2d6a7f7043111be4fdfc'
    #} 
    #config.action_mailer.delivery_method = :smtp
    #require 'german_date_names'

    # Custom directories with classes and modules you want to be autoloadable.
    # config.autoload_paths += %W(#{config.root}/extras)

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer
    config.active_record.observers = :user_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
     config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
     config.i18n.default_locale = :de
# The internationalization framework can be changed
# to have another default locale (standard is :en) or more load paths.
# All files from config/locales/*.rb,yml are added automatically.
#config.i18n.load_path += Dir[File.join(Rails.root.to_s, 'config', 'locales', '*.{rb,yml}')]
#["#{RAILS_ROOT}/config/locales/template.yml","#{RAILS_ROOT}/config/locales/template-en.yml","#{RAILS_ROOT}/config/locales/numbers.yml"]
#config.i18n.default_locale = :de
AVAILABLE_LOCALES = ["de", "en","fr"]


    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    # Enable the asset pipeline
    config.assets.enabled = true

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '1.0'
  end
end

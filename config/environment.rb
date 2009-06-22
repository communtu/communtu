# Be sure to restart your server when you modify this file

# Uncomment below to force Rails into production mode when
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'development'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.2.2' # unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')
require 'rails_generator/secret_key_generator'
Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.
  # See Rails::Configuration for more options.

  # Skip frameworks you're not going to use (only works if using vendor/rails).
  # To use Rails without a database, you must remove the Active Record framework
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

  # Only load the plugins named here, in the order given. By default, all plugins 
  # in vendor/plugins are loaded in alphabetical order.
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Force all environments to use the same logger level
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Your secret key for verifying cookie session data integrity.
  # If you change this key, all old sessions will become invalid!
  # Make sure the secret is at least 30 characters and all random, 
  # no regular words or you'll be exposed to dictionary attacks.
  secret_file = File.join(RAILS_ROOT, "secret")
  if File.exist?(secret_file)
    secret = File.read(secret_file)
  else
    secret = Rails::SecretKeyGenerator.new("insoshi").generate_secret
    File.open(secret_file, 'w') { |f| f.write(secret) }
  end
  config.action_controller.session = {
    :session_key     => '_communtu_session',
    :secret          => '367e4806af33b2cd7ddc839f908a7ed6844a3b369ce46724a3c419a633c1c68d612692d3f441ba2b31158e167c4bb5c81a5be173e83a2d6a7f7043111be4fdfc'
  }

  # use file system for session storing
  # config.action_controller.session_store = :p_store

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector

  # Make Active Record use UTC-base instead of local time
  # config.active_record.default_timezone = :utc
  
  config.active_record.observers = :user_observer

config.action_mailer.delivery_method = :smtp
require 'german_date_names'

# The internationalization framework can be changed
# to have another default locale (standard is :en) or more load paths.
# All files from config/locales/*.rb,yml are added automatically.
config.i18n.load_path += Dir[File.join(RAILS_ROOT, 'config', 'locales', '*.{rb,yml}')]
#["#{RAILS_ROOT}/config/locales/template.yml","#{RAILS_ROOT}/config/locales/template-en.yml","#{RAILS_ROOT}/config/locales/numbers.yml"]
config.i18n.default_locale = :de
AVAILABLE_LOCALES = [:de]
end

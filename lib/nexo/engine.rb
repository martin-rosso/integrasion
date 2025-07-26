require "googleauth"
require "google-apis-oauth2_v2"
require "google-apis-calendar_v3"
require "kaminari"

module Nexo
  def self.folder_rules
    ::Nexo::PolicyService.instance
  end

  def self.plain_logger
    @plain_logger ||=
      ActiveSupport::Logger.new(Rails.root.join("log/nexo-#{Rails.env}.log"))
        .tap  { |logger| logger.formatter = ::Logger::Formatter.new }
        .tap  { |logger| logger.level = ENV.fetch("NEXO_LOG_LEVEL", "debug") }
        .then { |logger| ActiveSupport::TaggedLogging.new(logger) }
  end

  def self.logger
    @logger ||= ActiveSupport::BroadcastLogger.new(plain_logger, Rails.logger)
  end

  mattr_accessor :api_jobs_throttle
  mattr_accessor :admin_controller_parent_class

  # The URL target for Google watch requests
  mattr_accessor :google_webhook_url

  # The token sent by google in every watch request
  mattr_accessor :google_webhook_token

  # Used to encode Google Calendar channel ids
  mattr_accessor :secret_token

  self.admin_controller_parent_class = ActionController::Base
  self.google_webhook_url = ENV.fetch("NEXO_GOOGLE_WEBHOOK_URL", nil)

  # @!visibility private
  class Engine < ::Rails::Engine
    isolate_namespace Nexo

    initializer "nexo.collapse_dirs" do
      dir = "#{root}/app/lib/nexo/api_client"
      Rails.autoloaders.main.collapse(dir)
    end

    initializer "nexo.setup_google_logger" do
      # Google::Apis.logger = Nexo.plain_logger
      Google::Apis.logger =
        ActiveSupport::Logger.new(Rails.root.join("log/google_apis.log"))
          .tap  { |logger| logger.formatter = ::Logger::Formatter.new }
          .then { |logger| ActiveSupport::TaggedLogging.new(logger) }
    end

    initializer "configurar_generators" do
      config.generators do |g|
        g.test_framework :rspec
        g.orm :active_record
      end
    end

    initializer "nexo.set_factory_paths", after: "factory_bot.set_factory_paths" do
      FactoryBot.definition_file_paths << "#{root}/spec/factories"
    end
  end
end

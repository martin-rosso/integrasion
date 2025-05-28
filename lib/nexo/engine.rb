require "googleauth"
require "google-apis-oauth2_v2"
require "google-apis-calendar_v3"

module Nexo
  def self.folder_policies
    ::Nexo::PolicyService.instance
  end

  mattr_accessor :api_jobs_throttle

  # @!visibility private
  class Engine < ::Rails::Engine
    isolate_namespace Nexo

    initializer "nexo.collapse_dirs" do
      dir = "#{root}/app/lib/nexo/api_client"
      Rails.autoloaders.main.collapse(dir)
    end

    initializer "nexo.setup_google_logger" do
      Google::Apis.logger = ActiveSupport::Logger.new(Rails.root.join("log/google_apis.log"))
        .tap  { |logger| logger.formatter = ::Logger::Formatter.new }
        .then { |logger| ActiveSupport::TaggedLogging.new(logger) }
      # .tap  { |logger| logger.push_tags("FOO") }
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

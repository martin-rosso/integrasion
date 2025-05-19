require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_mailbox/engine"
require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

Dotenv.load(".env.#{Rails.env}.local", ".env.#{Rails.env}", '.env.local', '.env')

module Dummy
  class Application < Rails::Application
    config.load_defaults Rails::VERSION::STRING.to_f

    # For compatibility with applications that use this config
    config.action_controller.include_all_helpers = false

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    config.time_zone = "America/Argentina/Buenos_Aires"

    # config.eager_load_paths << Rails.root.join("extras")

    # Don't generate system test files.
    config.generators.system_tests = nil

    config.i18n.default_locale = :es

    config.to_prepare do
      Nexo.rules.register_finder do |folder|
        if folder.name == "Other folder"
          DummyFolderRule.new("with_nil_sequence", :include, 1)
        end

        if folder.name == "Test calendar"
          DummyFolderRule.new("initialized", :include, 1)
        end
      end
      Nexo.rules.register_finder do |folder|
        if folder.name == "Nexo Automated Test"
          DummyFolderRule.new("Test event", :include, 1)
        else
          nil
        end
      end
    end
  end
end

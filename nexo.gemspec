require_relative "lib/nexo/version"

Gem::Specification.new do |spec|
  spec.name        = "nexo"
  spec.version     = Nexo::VERSION
  spec.authors     = [ "Martín Rosso" ]
  spec.email       = [ "mrosso10@gmail.com" ]
  spec.homepage    = "https://github.com/martin-rosso/nexo"
  spec.summary     = "Integrate a Rails app with external services"
  spec.license     = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the "allowed_push_host"
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  # spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  # spec.metadata["source_code_uri"] = "TODO: Put your gem's public repo URL here."
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 7.1"
  spec.add_dependency "google-apis-calendar_v3", "~> 0.46.0"
  spec.add_dependency "google-apis-oauth2_v2", "~> 0.19.0"
  spec.add_dependency "googleauth", "~> 1.14"
end

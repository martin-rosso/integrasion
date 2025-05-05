source "https://rubygems.org"

# Specify your gem's dependencies in integrasion.gemspec.
gemspec

gem "puma"

gem "sqlite3"

gem "sprockets-rails"

# Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
gem "rubocop-rails-omakase", require: false

# Start debugger with binding.b [https://github.com/ruby/debug]
# gem "debug", ">= 1.0.0"

group :development, :test do
  gem "rspec-rails", "~> 8.0.0"

  gem "simplecov"
  gem "simplecov-lcov"
  gem "undercover", "= 0.5.0"

  gem 'annotate', '~> 3.2.0'

  gem 'byebug'
end

# frozen_string_literal: true

source "https://rubygems.org"

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

# Specify your gem's dependencies in yookassa.gemspec
gem "rs-httpclient", "= 3.0.0.beta1"

gemspec

group :documentation do
  gem "rack", "~> 3.2"
  gem "webrick", "~> 1.9"
  gem "yard", "~> 0.9"
end

group :development, :test do
  gem "capybara", "~> 3.40"
  gem "cuprite", "~> 0.15"
  gem "pry", "~> 0.16"
  gem "pry-byebug", "~> 3.10"
  gem "rack-test", "~> 2.1"
  gem "rails", "~> 8.0"
  gem "rake", "~> 13.4"
  gem "rspec", "~> 3.13"
  gem "rubocop", "~> 1.88"
  gem "rubocop-rake", "~> 0.7"
  gem "rubocop-rspec", "~> 2.31"
  gem "simplecov", "~> 0.22"
  gem "sqlite3", "~> 2.0"
  gem "webmock", "~> 3.26"
end

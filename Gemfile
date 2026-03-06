# frozen_string_literal: true

source "https://rubygems.org"

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

# Specify your gem's dependencies in yookassa.gemspec
gemspec

group :documentation do
  gem "rack"
  gem "webrick"
  gem "yard"
end

group :development, :test do
  gem "capybara", "~> 3.40"
  gem "cuprite", "~> 0.15"
  gem "pry"
  gem "pry-byebug", "~> 3.10"
  gem "rake", "~> 13.0"
  gem "rack-test", "~> 2.1"
  gem "rails", "~> 8.0"
  gem "rspec", "~> 3.13"
  gem "sqlite3", "~> 2.0"
  gem "rubocop", "~> 1.60"
  gem "rubocop-rake", "~> 0.7"
  gem "rubocop-rspec", "~> 2.31"
  gem "simplecov", "~> 0.22"
  gem "webmock", "~> 3.23"
end

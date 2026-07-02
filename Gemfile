# frozen_string_literal: true

source "https://rubygems.org"

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

# Specify your gem's dependencies in yookassa.gemspec
gem "httpclient", github: "glebtv/httpclient", branch: "master"

gemspec

group :documentation do
  gem "rack", "~> 3.2"
  gem "webrick", "~> 1.9"
  gem "yard", "~> 0.9"
end

group :development, :test do
  gem "pry", "~> 0.16"
  gem "pry-byebug", "~> 3.8"
  gem "rake", "~> 13.4"
  gem "rspec", "~> 3.13"
  gem "rubocop", "~> 1.88"
  gem "rubocop-rake", "~> 0.6.0"
  gem "rubocop-rspec", "~> 2.31"
  gem "simplecov", "~> 0.22"
  gem "webmock", "~> 3.26"
end

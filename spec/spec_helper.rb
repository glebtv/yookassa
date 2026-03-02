# frozen_string_literal: true

begin
  require "pry"
rescue LoadError
  nil
end

require "yookassa"
require "webmock/rspec"
WebMock.disable_net_connect!(allow_localhost: true)

Dir[File.expand_path("support/**/*.rb", __dir__)].sort.each { |file| require file }

RSpec.configure do |config|
  config.order = :random
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true

  config.before do
    WebMock.reset!
  end
end

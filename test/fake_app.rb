require "rails"
require "active_model/railtie"
require "action_controller/railtie"
require "action_view/railtie"
require "verdict/railtie"

# Create a rails app
module Dummy
  class Application < Rails::Application
    config.root = "test"
  end
end

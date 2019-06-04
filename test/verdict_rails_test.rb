require 'test_helper'
require 'fake_app'

class VerdictRailsTest < Minitest::Test
  def setup
    Verdict.clear_repository_cache
    new_rails_app = Dummy::Application.new
    new_rails_app.initialize!
  end

  def test_verdict_railtie_should_find_directory_path
    assert_equal Verdict.directory, Rails.root.join('app', 'experiments')
  end

  def test_verdict_should_eager_load_discovery
    expected_experiment = Verdict.instance_variable_get('@repository')
    assert expected_experiment.include?("test_rails_app_experiment")
  end
end
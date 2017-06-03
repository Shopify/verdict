require 'test_helper'

class ExperimentTest < Minitest::Test

  def test_json_export
    e1 = Verdict::Experiment.define('test_1') { groups { group :all, 100 } }
    e2 = Verdict::Experiment.define('test_2') { groups { group :all, 100 } }

    json = JSON.parse(Verdict.repository.to_json)
    assert_equal ['test_1', 'test_2'], json.keys
    assert_equal json['test_1'], JSON.parse(e1.to_json)
  end
end

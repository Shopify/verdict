require 'test_helper'

class ExperimentTest < Minitest::Test

  def setup
    Verdict.repository.clear
  end

  def test_should_keep_list_of_all_experiments
    size_at_start = Verdict.repository.size
    e = Verdict::Experiment.define('test')

    assert_equal size_at_start + 1, Verdict.repository.size
    assert_equal e, Verdict['test']
  end

  def test_should_not_allow_experiments_with_the_same_name
    Verdict::Experiment.define('test_duplicate')
    assert_raises(Verdict::ExperimentHandleNotUnique) do
      Verdict::Experiment.define('test_duplicate')
    end
  end

  def test_json_export
    e1 = Verdict::Experiment.define('test_1') { groups { group :all, 100 } }
    e2 = Verdict::Experiment.define('test_2') { groups { group :all, 100 } }

    json = JSON.parse(Verdict.repository.to_json)
    assert_equal ['test_1', 'test_2'], json.keys
    assert_equal json['test_1'], JSON.parse(e1.to_json)
  end
end

require 'test_helper'

class ExperimentTest < MiniTest::Unit::TestCase

  def setup
    Experiments.repository.clear
  end

  def test_should_keep_list_of_all_experiments
    size_at_start = Experiments.repository.size
    e = Experiments::Experiment.define('test')

    assert_equal size_at_start + 1, Experiments.repository.size
    assert_equal e, Experiments['test']
  end

  def test_should_not_allow_experiments_with_the_same_name
    Experiments::Experiment.define('test_duplicate')
    assert_raises(Experiments::ExperimentHandleNotUnique) do
      Experiments::Experiment.define('test_duplicate')
    end
  end

  def test_json_export
    e1 = Experiments::Experiment.define('test_1') { groups { group :all, 100 } }
    e2 = Experiments::Experiment.define('test_2') { groups { group :all, 100 } }

    json = JSON.parse(Experiments.repository.to_json)
    assert_equal ['test_1', 'test_2'], json.keys
    assert_equal json['test_1'], JSON.parse(e1.to_json)
  end
end

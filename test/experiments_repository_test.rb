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
end
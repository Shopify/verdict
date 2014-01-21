require 'test_helper'

class RolloutPercentageSegmenterTest < MiniTest::Unit::TestCase

  def setup
    @experiment = Verdict::Experiment.new('test') do
      rollout_percentage 50
    end
  end

  def test_assignment
    included_subject = stub(id: 1)
    excluded_subject = stub(id: 2)
    
    included_assignment = @experiment.assign(included_subject)
    assert included_assignment.qualified?
    assert included_assignment.permanent?

    excluded_assignment = @experiment.assign(excluded_subject)
    assert !excluded_assignment.qualified?
    assert excluded_assignment.temporary?
  end

  def test_group_json_representation
    json = JSON.parse(@experiment.segmenter.groups['enabled'].to_json)
    assert_equal 'enabled', json['handle']
    assert_equal 50, json['percentage']
  end
end

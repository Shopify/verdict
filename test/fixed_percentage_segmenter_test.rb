require 'test_helper'

class FixedPercentageSegmenterTest < MiniTest::Unit::TestCase

  def test_add_up_to_100_percent
    s = Verdict::FixedPercentageSegmenter.new(Verdict::Experiment.new('test'))
    s.group :segment1, 1
    s.group :segment2, 54
    s.group :segment3, 27
    s.group :segment4, 18
    s.verify!

    assert_equal ['segment1', 'segment2', 'segment3', 'segment4'], s.groups.keys
    assert_equal  0 ...   1, s.groups['segment1'].percentile_range
    assert_equal  1 ...  55, s.groups['segment2'].percentile_range
    assert_equal 55 ...  82, s.groups['segment3'].percentile_range
    assert_equal 82 ... 100, s.groups['segment4'].percentile_range
  end

  def test_definition_ofhalf_and_rest
    s = Verdict::FixedPercentageSegmenter.new(Verdict::Experiment.new('test'))
    s.group :first_half, :half
    s.group :second_half, :rest
    s.verify!

    assert_equal ['first_half', 'second_half'], s.groups.keys
    assert_equal  0 ...  50, s.groups['first_half'].percentile_range
    assert_equal 50 ... 100, s.groups['second_half'].percentile_range
  end

  def test_raises_if_less_than_100_percent
    assert_raises(Verdict::SegmentationError) do
      s = Verdict::FixedPercentageSegmenter.new(Verdict::Experiment.new('test'))
      s.group :too_little, 99
      s.verify!
    end
  end

  def test_raises_if_greather_than_100_percent
    assert_raises(Verdict::SegmentationError) do
      s = Verdict::FixedPercentageSegmenter.new(Verdict::Experiment.new('test'))
      s.group :too_much, 101
      s.verify!
    end
  end

  def test_consistent_assignment_for_subjects
    s = Verdict::FixedPercentageSegmenter.new(Verdict::Experiment.new('test'))
    s.group :first_half, :half
    s.group :second_half, :rest
    s.verify!

    3.times do 
      assert s.groups['first_half']  === s.assign(1, nil, nil)
      assert s.groups['second_half'] === s.assign(2, nil, nil)
    end
  end

  def test_fair_segmenting
    s = Verdict::FixedPercentageSegmenter.new(Verdict::Experiment.new('test'))
    s.group :first_third, 33
    s.group :second_third, 33
    s.group :final_third, :rest
    s.verify!

    assignments = { :first_third => 0, :second_third => 0, :final_third => 0 }
    200.times do |n| 
      assignment = s.assign(n, nil, nil) 
      assignments[assignment.to_sym] += 1
    end

    assert_equal 200, assignments.values.reduce(0, :+)
    assert (60..72).include?(assignments[:first_third]),  'The groups should be roughly the same size.'
    assert (60..72).include?(assignments[:second_third]), 'The groups should be roughly the same size.'
    assert (60..72).include?(assignments[:final_third]),  'The groups should be roughly the same size.'
  end

  def test_group_json_export
    s = Verdict::FixedPercentageSegmenter.new(Verdict::Experiment.new('test'))
    s.group :first_third, 33
    s.group :rest, :rest
    s.verify!

    json = JSON.parse(s.groups['rest'].to_json)
    assert_equal 'rest', json['handle']
    assert_equal 67, json['percentage']
  end
end

require 'test_helper'

class StaticPercentageSegmenterTest < MiniTest::Unit::TestCase

  MockExperiment = Struct.new(:name)

  def setup
    Experiments.repository.clear
  end

  def test_add_up_to_100_percent
    s = Experiments::Segmenter::StaticPercentage.new(MockExperiment.new('test'))
    s.group :segment1, 1
    s.group :segment2, 54
    s.group :segment3, 27
    s.group :segment4, 18
    s.verify!

    assert_equal [:segment1, :segment2, :segment3, :segment4], s.groups.keys
    assert_equal  0 ...   1, s.groups[:segment1]
    assert_equal  1 ...  55, s.groups[:segment2]
    assert_equal 55 ...  82, s.groups[:segment3]
    assert_equal 82 ... 100, s.groups[:segment4]
  end

  def test_defintiion_ofhalf_and_rest
    s = Experiments::Segmenter::StaticPercentage.new(MockExperiment.new('test'))
    s.group :first_half, :half
    s.group :second_half, :rest
    s.verify!

    assert_equal [:first_half, :second_half], s.groups.keys
    assert_equal  0 ...  50, s.groups[:first_half]
    assert_equal 50 ... 100, s.groups[:second_half]
  end

  def test_raises_if_less_than_100_percent
    assert_raises(Experiments::SegmentationError) do
      s = Experiments::Segmenter::StaticPercentage.new(MockExperiment.new('test'))
      s.group :too_little, 99
      s.verify!
    end
  end

  def test_raises_if_greather_than_100_percent
    assert_raises(Experiments::SegmentationError) do
      s = Experiments::Segmenter::StaticPercentage.new(MockExperiment.new('test'))
      s.group :too_much, 101
      s.verify!
    end
  end

  def test_consistent_segmentatation_for_subjects
    e = Experiments::Experiment.new('test') do
      groups do
        group :a, :half
        group :b, :rest
      end
    end

    assert_equal :a, e.assign(1)
    assert_equal :b, e.assign(2)
  end

  def test_fair_segmenting
    s = Experiments::Segmenter::StaticPercentage.new(MockExperiment.new('test'))
    s.group :first_third, 33
    s.group :second_third, 33
    s.group :final_third, :rest
    s.verify!

    assignments = { :first_third => 0, :second_third => 0, :final_third => 0 }
    200.times { |n| assignments[s.assign(n, nil, nil)] += 1 }

    assert_equal 200, assignments.values.reduce(0, :+)
    assert (60..72).include?(assignments[:first_third]),  'The groups should be roughly the expected size.'
    assert (60..72).include?(assignments[:second_third]), 'The groups should be roughly the expected size.'
    assert (60..72).include?(assignments[:final_third]),  'The groups should be roughly the expected size.'
  end
end

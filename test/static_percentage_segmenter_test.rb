require 'test_helper'

class StaticPercentageSegmenterTest < MiniTest::Unit::TestCase

  MockExperiment = Struct.new(:name)

  def test_add_up_to_100_percent
    s = Experiments::Segmenter::StaticPercentage.new(MockExperiment.new('test'))
    s.percentage  1, :segment1
    s.percentage 54, :segment2
    s.percentage 27, :segment3
    s.percentage 18, :segment4
    s.verify!

    assert_equal [:segment1, :segment2, :segment3, :segment4], s.segments.keys
    assert_equal  0 ...   1, s.segments[:segment1]
    assert_equal  1 ...  55, s.segments[:segment2]
    assert_equal 55 ...  82, s.segments[:segment3]
    assert_equal 82 ... 100, s.segments[:segment4]
  end

  def test_defintiion_ofhalf_and_rest
    s = Experiments::Segmenter::StaticPercentage.new(MockExperiment.new('test'))
    s.half :first_half
    s.rest :second_half
    s.verify!

    assert_equal [:first_half, :second_half], s.segments.keys
    assert_equal  0 ...  50, s.segments[:first_half]
    assert_equal 50 ... 100, s.segments[:second_half]
  end

  def test_raises_if_less_than_100_percent
    assert_raises(Experiments::Segmenter::SegmentationError) do
      s = Experiments::Segmenter::StaticPercentage.new(MockExperiment.new('test'))
      s.percentage 99, :too_little
      s.verify!
    end
  end

  def test_raises_if_greather_than_100_percent
    assert_raises(Experiments::Segmenter::SegmentationError) do
      s = Experiments::Segmenter::StaticPercentage.new(MockExperiment.new('test'))
      s.percentage 101, :too_much
      s.verify!
    end
  end

  def test_consistent_segmentatation_for_subjects
    e = Experiments::Experiment.new('test') do |segment|
      segment.half :a
      segment.rest :b
    end

    assert_equal :a, e.segment_for(1)
    assert_equal :b, e.segment_for(2)
  end

  def test_fair_segmenting
    s = Experiments::Segmenter::StaticPercentage.new(MockExperiment.new('test'))
    s.percentage 33, :first_third
    s.percentage 33, :second_third
    s.rest           :final_third
    s.verify!

    segments = { :first_third => 0, :second_third => 0, :final_third => 0 }
    200.times { |n| segments[s.segment(n, nil, nil)] += 1 }

    assert_equal 200, segments.values.reduce(0, :+)
    assert (60..72).include?(segments[:first_third]),  'The segments should be roughly the expected size.'
    assert (60..72).include?(segments[:second_third]), 'The segments should be roughly the expected size.'
    assert (60..72).include?(segments[:final_third]),  'The segments should be roughly the expected size.'
  end
end

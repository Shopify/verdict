require 'test_helper'

class RandomPercentageSegmenterTest < Minitest::Test

  def setup
    @segmenter = Verdict::Segmenters::RandomPercentageSegmenter.new(Verdict::Experiment.new('test'))
    @segmenter.group :segment1, 50
    @segmenter.group :segment2, 50
    @segmenter.verify!
  end

  def test_random_assignment
    @segmenter.random = Random.new(1)

    groups = { segment1: 0, segment2: 0 }
    100.times do |n|
      group = @segmenter.assign(n.to_s, nil, nil)
      groups[group.handle.to_sym] += 1
    end

    assert_equal 54, groups[:segment1]
    assert_equal 46, groups[:segment2]
  end

  def test_random_assignment_with_different_seed
    @segmenter.random = Random.new(2)

    groups = { segment1: 0, segment2: 0 }
    100.times do |n|
      group = @segmenter.assign(n.to_s, nil, nil)
      groups[group.handle.to_sym] += 1
    end

    assert_equal 44, groups[:segment1]
    assert_equal 56, groups[:segment2]
  end
end

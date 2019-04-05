require 'test_helper'

class BetaBernoulliSegmenterTest < Minitest::Test

  def test_raises_if_alpha_parameter_0_or_less
    assert_raises(Verdict::PriorError) do
      s = Verdict::Segmenters::BetaBernoulliSegmenter.new(Verdict::Experiment.new('test'))
        s.group :bad_alpha, 0, 2
      s.verify!
    end
  end

  def test_raises_if_beta_parameter_0_or_less
    assert_raises(Verdict::PriorError) do
      s = Verdict::Segmenters::BetaBernoulliSegmenter.new(Verdict::Experiment.new('test'))
        s.group :bad_beta, -1, 2
      s.verify!
    end
  end

  def test_correct_assignment
    
    s = Verdict::Segmenters::BetaBernoulliSegmenter.new(Verdict::Experiment.new('test'))
    s.group :a, 2, 2
    s.group :b, 2, 2
    s.group :c, 2, 2

    srand(1234)
    assert_equal [0.2801846935879799, 0.5821449090588785, 0.45838909543963763], s.rng
    srand(1234)
    assert_equal s.groups.values[1], s.assign('1', '1', nil)
  end

  def test_correct_prior_update
    s = Verdict::Segmenters::BetaBernoulliSegmenter.new(Verdict::Experiment.new('test'))
    s.group :a, 2, 2
    s.verify!

    s.groups['a'].update_prior 1, -1
    assert_equal 3, s.groups['a'].alpha
    assert_equal 1, s.groups['a'].beta
  end

  def test_prior_update_with_conversion
    e = Verdict::Experiment.new('test') do
      groups Verdict::Segmenters::BetaBernoulliSegmenter do
        group :a, 2, 2
        group :b, 2, 2
      end
    end 

    e.assign_manually('1', e.groups['a'])
    e.assign_manually('2', e.groups['b'])
    e.convert('1', 1)   
    e.convert('2', 0)

    assert_equal 3, e.groups['a'].alpha
    assert_equal 2, e.groups['a'].beta
    assert_equal 2, e.groups['b'].alpha
    assert_equal 3, e.groups['b'].beta
  end
end

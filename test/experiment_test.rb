require 'test_helper'

class ExperimentTest < MiniTest::Unit::TestCase

  def test_add_up_to_100_percent
    e = Experiments::Experiment.new('test') do |group|
      group.percentage  1, :group1
      group.percentage 54, :group2
      group.percentage 27, :group3
      group.percentage 18, :group4
    end

    assert_equal [:group1, :group2, :group3, :group4], e.groups.keys
    assert_equal  0 ...   1, e.groups[:group1]
    assert_equal  1 ...  55, e.groups[:group2]
    assert_equal 55 ...  82, e.groups[:group3]
    assert_equal 82 ... 100, e.groups[:group4]
  end

  def test_half_and_rest
    e = Experiments::Experiment.new('test') do |group|
      group.half :first_half
      group.rest :second_half
    end

    assert_equal [:first_half, :second_half], e.groups.keys
    assert_equal  0 ...  50, e.groups[:first_half]
    assert_equal 50 ... 100, e.groups[:second_half]
  end
  
  def test_raises_if_less_than_100_percent
    assert_raises(Experiments::Experiment::AssignmentError) do
      Experiments::Experiment.new('test') do |group|
        group.percentage 99, :too_little
      end
    end
  end
  
  def test_raises_if_greather_than_100_percent
    assert_raises(Experiments::Experiment::AssignmentError) do
      Experiments::Experiment.new('test') do |group|
        group.percentage 101, :too_much
      end
    end
  end
  
  def test_group_for_identifier
    Experiments.logger = MiniTest::Mock.new
    e = Experiments::Experiment.new('test') do |group|
      group.half :a
      group.rest :b
    end

    Experiments.logger.expect(:info, nil, ['[test] subject id 1 is in group :a'])
    Experiments.logger.expect(:info, nil, ['[test] subject id 2 is in group :b'])
    
    assert_equal :a, e.group_for(1)
    assert_equal :b, e.group_for(2)

     Experiments.logger.verify
  end

  def test_group_for
    e = Experiments::Experiment.new('test') do |group|
      group.half :a
      group.rest :b
    end

    object_stub = Struct.new(:id)
    assert_equal :a, e.group_for(object_stub.new(1))
    assert_equal :b, e.group_for(object_stub.new(2))
  end

  def test_fair_grouping
    e = Experiments::Experiment.new('test') do |group|
      group.percentage 33, :first_third
      group.percentage 33, :second_third
      group.rest           :final_third
    end
    
    groups = { :first_third => 0, :second_third => 0, :final_third => 0 }
    200.times { |n| groups[e.group_for(n)] += 1 }

    assert_equal 200, groups.values.reduce(0, :+)
    assert (60..72).include?(groups[:first_third]),  'The groups should be roughly the expected size.'
    assert (60..72).include?(groups[:second_third]), 'The groups should be roughly the expected size.'
    assert (60..72).include?(groups[:final_third]),  'The groups should be roughly the expected size.'
  end
end

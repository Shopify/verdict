require 'test_helper'

class ExperimentTest < ActiveSupport::TestCase

  def test_add_up_to_100_percent
    assert_nothing_raised do
      Experiment.new('test') do |group|
        group.percentage  1, :group1
        group.percentage 54, :group2
        group.percentage 27, :group3
        group.percentage 18, :group4
      end
    end
  end
  
  def test_raises_if_less_than_100_percent
    assert_raises(Experiment::AssignmentError) do
      Experiment.new('test') do |group|
        group.percentage 99, :too_much
      end
    end
  end
  
  def test_raises_if_greather_than_100_percent
    assert_raises(Experiment::AssignmentError) do
      Experiment.new('test') do |group|
        group.percentage 101, :too_much
      end
    end
  end
  
  def test_half_and_rest
    assert_nothing_raised do
      Experiment.new('test') do |group|
        group.half :first_half
        group.rest :second_half
      end
    end
  end
  
  def test_group_for_identifier
    e = Experiment.new('test') do |group|
      group.half :a
      group.rest :b
    end

    Rails.logger.expects(:info).once.with('[test] subject id 1 is in group :a')
    Rails.logger.expects(:info).once.with('[test] subject id 2 is in group :b')
    
    assert_equal :a, e.group_for(1)
    assert_equal :b, e.group_for(2)
  end

  def test_group_for
    e = Experiment.new('test') do |group|
      group.half :a
      group.rest :b
    end
    object = stub(:object)
    object.stubs(:id => 1)

    assert_equal :a, e.group_for(object)

    object.stubs(:id => 2)
    assert_equal :b, e.group_for(object)
  end

  def test_fair_grouping
    e = Experiment.new('test') do |group|
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

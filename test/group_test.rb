require 'test_helper'

class GroupTest < MiniTest::Unit::TestCase

  def setup
    @experiment = Experiments::Experiment.new('a')
  end

  def test_basic_properties
    group = Experiments::Group.new(@experiment, :test)

    assert_equal @experiment, group.experiment
    assert_kind_of Experiments::Group, group
    assert_equal 'test', group.handle
    assert_equal 'test', group.to_s
    assert_equal :test, group.to_sym
  end

  def test_triple_equals
    group = Experiments::Group.new(@experiment, 'control')
    assert group === Experiments::Group.new(@experiment, :control)
    assert group === 'control'
    assert group === :control
    assert !(group === nil)

    assert !(group === Experiments::Group.new(@experiment, :test))
    assert !(group === Experiments::Group.new(Experiments::Experiment.new('b'), :test))
    assert !(group === 'test')
    assert !(group === nil)
  end

  def test_json
    group = Experiments::Group.new(@experiment, 'control')
    group.name 'testing'
    group.description 'description'

    json = JSON.parse(group.to_json)
    assert_equal 'control', json['handle']
    assert_equal 'testing', json['metadata']['name']
    assert_equal 'description', json['metadata']['description']
  end  
end

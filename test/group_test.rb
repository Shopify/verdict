require 'test_helper'

class GroupTest < Minitest::Test

  def setup
    @experiment = Verdict::Experiment.new('a')
  end

  def test_basic_properties
    group = Verdict::Group.new(@experiment, :test)

    assert_equal @experiment, group.experiment
    assert_kind_of Verdict::Group, group
    assert_equal 'test', group.handle
    assert_equal 'test', group.to_s
    assert_equal :test, group.to_sym
  end

  def test_triple_equals
    group = Verdict::Group.new(@experiment, 'control')
    assert group === Verdict::Group.new(@experiment, :control)
    assert group === 'control'
    assert group === :control
    assert !(group === nil)

    assert !(group === Verdict::Group.new(@experiment, :test))
    assert !(group === Verdict::Group.new(Verdict::Experiment.new('b'), :test))
    assert !(group === 'test')
    assert !(group === nil)
  end

  def test_json
    group = Verdict::Group.new(@experiment, 'control')
    group.name 'testing'
    group.description 'description'

    json = JSON.parse(group.to_json)
    assert_equal 'control', json['handle']
    assert_equal 'testing', json['metadata']['name']
    assert_equal 'description', json['metadata']['description']
  end
end

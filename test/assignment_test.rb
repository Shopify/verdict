require 'test_helper'
require 'json'

class AssignmentTest < Minitest::Test

  def setup
    @experiment = Verdict::Experiment.new('assignment test')
    @group = Verdict::Group.new(@experiment, :control)
  end

  def test_basic_properties
    assignment = Verdict::Assignment.new(@experiment, 'test_subject_id', @group, Time.now.utc)
    assert_equal 'test_subject_id', assignment.subject_identifier
    assert_equal @experiment, assignment.experiment
    assert_equal @group, assignment.group
    assert assignment.returning?
    assert assignment.qualified?
    assert_equal :control, assignment.to_sym
    assert_equal 'control', assignment.handle
    assert_kind_of Time, assignment.created_at

    non_assignment = Verdict::Assignment.new(@experiment, 'test_subject_id', nil, nil)
    assert_equal nil, non_assignment.group
    assert !non_assignment.returning?
    assert !non_assignment.qualified?
    assert_equal nil, non_assignment.to_sym
    assert_equal nil, non_assignment.handle
    assert_kind_of Time, assignment.created_at
  end

  def test_subject_lookup
    assignment = Verdict::Assignment.new(@experiment, 'test_subject_id', nil, Time.now.utc)
    assert_raises(NotImplementedError) { assignment.subject }

    @experiment.expects(:fetch_subject).with('test_subject_id').returns(subject = mock('subject'))
    assignment = Verdict::Assignment.new(@experiment, 'test_subject_id', nil, Time.now.utc)
    assert_equal subject, assignment.subject
  end

  def test_triple_equals
    assignment = Verdict::Assignment.new(@experiment, 'test_subject_id', @group, Time.now.utc)
    assert !(assignment === nil)
    assert assignment === @group
    assert assignment === 'control'
    assert assignment === :control

    non_assignment = Verdict::Assignment.new(@experiment, 'test_subject_id', nil, Time.now.utc)
    assert non_assignment === nil
    assert !(non_assignment === @group)
    assert !(non_assignment === 'control')
    assert !(non_assignment === :control)
  end

  def test_json_representation
    assignment = Verdict::Assignment.new(@experiment, 'test_subject_id', @group, Time.new(2013, 1, 1, 0, 0, 0, '+00:00'))
    json = JSON.parse(assignment.to_json)

    assert_equal 'assignment test', json['experiment']
    assert_equal 'test_subject_id', json['subject']
    assert_equal true, json['qualified']
    assert_equal true, json['returning']
    assert_equal 'control', json['group']
    assert_equal '2013-01-01T00:00:00Z', json['created_at']

    Timecop.freeze(Time.new(2012, 1, 1, 0, 0, 0, '+00:00')) do
      non_assignment = Verdict::Assignment.new(@experiment, 'test_subject_id', nil, nil)
      json = JSON.parse(non_assignment.to_json)
      assert_equal 'assignment test', json['experiment']
      assert_equal 'test_subject_id', json['subject']
      assert_equal false, json['qualified']
      assert_equal false, json['returning']
      assert_equal nil, json['group']
      assert_equal '2012-01-01T00:00:00Z', json['created_at']
    end
  end

  def test_returning_assignment
    assignment_with_timestamp = Verdict::Assignment.new(@experiment, 'test_subject_id', @group, Time.now.utc)
    assert assignment_with_timestamp.returning?

    assignment_without_timestamp = Verdict::Assignment.new(@experiment, 'test_subject_id', @group, nil)
    refute assignment_without_timestamp.returning?
  end

  def test_returning_with_timestamps_out_of_band_experiment_option
    experiment = Verdict::Experiment.new('assignment test', timestamps_out_of_band: true)

    assignment_with_timestamp = Verdict::Assignment.new(experiment, 'test_subject_id', @group, Time.now.utc)
    refute assignment_with_timestamp.returning?

    assignment_without_timestamp = Verdict::Assignment.new(experiment, 'test_subject_id', @group, nil)
    refute assignment_without_timestamp.returning?
  end
end

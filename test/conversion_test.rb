require 'test_helper'
require 'json'

class ConversionTest < Minitest::Test

  def setup
    @experiment = Verdict::Experiment.new('conversion test') do
      groups { group :all, 100 }
    end
  end

  def test_subject_lookup
    conversion = Verdict::Conversion.new(@experiment, 'test_subject_id', :test_goal)
    assert_raises(NotImplementedError) { conversion.subject }

    @experiment.expects(:fetch_subject).with('test_subject_id').returns(subject = mock('subject'))
    conversion = Verdict::Conversion.new(@experiment, 'test_subject_id', :test_goal)
    assert_equal subject, conversion.subject
  end

  def test_assignment_lookup
    @experiment.subject_storage.expects(:retrieve_assignment).with(@experiment, 'test_subject_id')
    conversion = Verdict::Conversion.new(@experiment, 'test_subject_id', :test_goal)
    conversion.assignment
  end

  def test_json_representation
    conversion = Verdict::Conversion.new(@experiment, 'test_subject_id', :test_goal, Time.new(2013, 1, 1, 4, 5, 6, '+00:00'))
    json = JSON.parse(conversion.to_json)

    assert_equal 'conversion test',      json['experiment']
    assert_equal 'test_subject_id',      json['subject']
    assert_equal 'test_goal',            json['goal']
    assert_equal 'test_goal',            json['goal']
    assert_equal '2013-01-01T04:05:06Z', json['created_at']
  end
end

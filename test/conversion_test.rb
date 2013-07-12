require 'test_helper'
require 'json'

class ConversionTest < MiniTest::Unit::TestCase

  def setup
    @experiment = Experiments::Experiment.new('conversion test') do
      groups { group :all, 100 }
    end
  end

  def test_subject_lookup
    conversion = Experiments::Conversion.new(@experiment, 'test_subject_id', :test_goal)
    assert_raises(NotImplementedError) { conversion.subject }

    @experiment.expects(:fetch_subject).with('test_subject_id').returns(subject = mock('subject'))
    conversion = Experiments::Conversion.new(@experiment, 'test_subject_id', :test_goal)
    assert_equal subject, conversion.subject
  end

  def test_assignment_lookup
    @experiment.subject_storage.expects(:retrieve_assignment).with(@experiment, 'test_subject_id')
    conversion = Experiments::Conversion.new(@experiment, 'test_subject_id', :test_goal)
    conversion.assignment
  end

  def test_json_representation
    conversion = Experiments::Conversion.new(@experiment, 'test_subject_id', :test_goal)
    json = JSON.parse(conversion.to_json)

    assert_equal 'conversion test',  json['experiment']
    assert_equal 'test_subject_id',  json['subject']
    assert_equal 'test_goal',        json['goal']
  end
end

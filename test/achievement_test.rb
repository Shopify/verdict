require 'test_helper'
require 'json'

class AchievementTest < MiniTest::Unit::TestCase

  def setup
    @experiment = Experiments::Experiment.new('achievement test') do
      groups { group :all, 100 }
    end
  end

  def test_subject_lookup
    achievement = Experiments::Achievement.new(@experiment, 'test_subject_id', :test_achievement)
    assert_raises(NotImplementedError) { achievement.subject }

    @experiment.expects(:fetch_subject).with('test_subject_id').returns(subject = mock('subject'))
    achievement = Experiments::Achievement.new(@experiment, 'test_subject_id', :test_achievement)
    assert_equal subject, achievement.subject
  end

  def test_assignment_lookup
    @experiment.subject_storage.expects(:retrieve_assignment).with(@experiment, 'test_subject_id')
    achievement = Experiments::Achievement.new(@experiment, 'test_subject_id', :test_achievement)
    achievement.assignment
  end

  def test_json_representation
    achievement = Experiments::Achievement.new(@experiment, 'test_subject_id', :test_achievement)
    json = JSON.parse(achievement.to_json)

    assert_equal 'achievement test', json['experiment']
    assert_equal 'test_subject_id',  json['subject']
    assert_equal 'test_achievement', json['label']
  end
end

require 'test_helper'

class EventLoggerTest < MiniTest::Unit::TestCase

  def setup
    @experiment = Experiments::Experiment.new(:logger) do
      groups { group :all, 100}
    end

    @logger = mock('logger')
    @event_logger = Experiments::EventLogger.new(@logger, :debug)
  end

  def test_log_unqualified_returning_assignment
    @logger.expects(:debug).with('[Experiments] experiment=logger subject=subject status=returning qualified=false')
    assignment = Experiments::Assignment.new(@experiment, 'subject', nil, true)
    @event_logger.log_assignment(assignment)
  end

  def test_log_unqualified_new_assignment
    @logger.expects(:debug).with('[Experiments] experiment=logger subject=subject status=new qualified=false')
    assignment = Experiments::Assignment.new(@experiment, 'subject', nil, false)
    @event_logger.log_assignment(assignment)
  end

  def test_log_qualified_returning_assignment
    @logger.expects(:debug).with('[Experiments] experiment=logger subject=subject status=returning qualified=true group=all')
    assignment = Experiments::Assignment.new(@experiment, 'subject', @experiment.group(:all), true)
    @event_logger.log_assignment(assignment)
  end

  def test_log_qualified_new_assignment
    @logger.expects(:debug).with('[Experiments] experiment=logger subject=subject status=new qualified=true group=all')
    assignment = Experiments::Assignment.new(@experiment, 'subject', @experiment.group(:all), false)
    @event_logger.log_assignment(assignment)
  end  
end

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
    @logger.expects(:debug).with('[Experiments::Assignment] experiment=logger subject=subject status=returning qualified=false')
    assignment = Experiments::Assignment.new(@experiment, 'subject', nil, Time.now)
    @event_logger.log_assignment(assignment)
  end

  def test_log_unqualified_new_assignment
    @logger.expects(:debug).with('[Experiments::Assignment] experiment=logger subject=subject status=new qualified=false')
    assignment = Experiments::Assignment.new(@experiment, 'subject', nil, nil)
    @event_logger.log_assignment(assignment)
  end

  def test_log_qualified_returning_assignment
    @logger.expects(:debug).with('[Experiments::Assignment] experiment=logger subject=subject status=returning qualified=true group=all')
    assignment = Experiments::Assignment.new(@experiment, 'subject', @experiment.group(:all), Time.now)
    @event_logger.log_assignment(assignment)
  end

  def test_log_qualified_new_assignment
    @logger.expects(:debug).with('[Experiments::Assignment] experiment=logger subject=subject status=new qualified=true group=all')
    assignment = Experiments::Assignment.new(@experiment, 'subject', @experiment.group(:all), nil)
    @event_logger.log_assignment(assignment)
  end

  def test_log_conversion
    @logger.expects(:debug).with('[Experiments::Conversion] experiment=logger subject=subject goal=my_goal')
    conversion = Experiments::Conversion.new(@experiment, 'subject', :my_goal)
    @event_logger.log_conversion(conversion)
  end
end

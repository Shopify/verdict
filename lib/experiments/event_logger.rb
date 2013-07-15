class Experiments::EventLogger
  attr_reader :logger, :level

  def initialize(logger, level = :info)
    @logger, @level = logger, level
  end

  def log_assignment(assignment)
    status = assignment.returning? ? 'returning' : 'new'
    if assignment.qualified?
      logger.send(level, "[Experiments::Assignment] experiment=#{assignment.experiment.handle} subject=#{assignment.subject_identifier} status=#{status} qualified=true group=#{assignment.group.handle}")
    else
      logger.send(level, "[Experiments::Assignment] experiment=#{assignment.experiment.handle} subject=#{assignment.subject_identifier} status=#{status} qualified=false")
    end 
  end

  def log_conversion(conversion)
    logger.send(level, "[Experiments::Conversion] experiment=#{conversion.experiment.handle} subject=#{conversion.subject_identifier} goal=#{conversion.goal}")
  end
end

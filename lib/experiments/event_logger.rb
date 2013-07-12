class Experiments::EventLogger
  attr_reader :logger, :level

  def initialize(logger, level = :info)
    @logger, @level = logger, level
  end

  def log_assignment(assignment)
    status = assignment.returning? ? 'returning' : 'new'
    if assignment.qualified?
      logger.send(level, "[Experiments] experiment=#{assignment.experiment.handle} subject=#{assignment.subject_identifier} status=#{status} qualified=true group=#{assignment.group.handle}")
    else
      logger.send(level, "[Experiments] experiment=#{assignment.experiment.handle} subject=#{assignment.subject_identifier} status=#{status} qualified=false")
    end 
  end

  def log_achievement(achievement)
    logger.send(level, "[Experiments] experiment=#{achievement.experiment.handle} subject=#{achievement.subject_identifier} achievement=#{achievement.label}")
  end
end

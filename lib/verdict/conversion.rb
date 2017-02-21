class Verdict::Conversion

  attr_reader :experiment, :subject, :goal, :created_at

  def initialize(experiment, subject, goal, created_at = Time.now.utc)
    @experiment = experiment
    @subject = subject
    @goal = goal
    @created_at = created_at
  end

  def subject_identifier
    experiment.retrieve_subject_identifier(subject)
  end

  def assignment
    experiment.lookup(subject)
  end

  def as_json(options = {})
    {
      experiment: experiment.handle,
      subject:    subject_identifier,
      goal:       goal,
      created_at: created_at.utc.strftime('%FT%TZ')
    }
  end

  def to_json(options = {})
    as_json(options).to_json
  end
end

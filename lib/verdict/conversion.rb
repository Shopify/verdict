class Verdict::Conversion

  attr_reader :experiment, :subject_identifier, :goal, :created_at

  def initialize(experiment, subject_identifier, goal, created_at = Time.now.utc)
    @experiment = experiment
    @subject_identifier = subject_identifier
    @goal = goal
    @created_at = created_at
  end

  def subject
    experiment.fetch_subject(subject_identifier)
  end

  def assignment
    experiment.fetch_assignment(subject_identifier)
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

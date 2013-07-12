class Experiments::Conversion

  attr_reader :experiment, :subject_identifier, :goal

  def initialize(experiment, subject_identifier, goal)
    @experiment, @subject_identifier, @goal = experiment, subject_identifier, goal
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
      goal:       goal
    }
  end

  def to_json(options = {})
    as_json(options).to_json
  end
end

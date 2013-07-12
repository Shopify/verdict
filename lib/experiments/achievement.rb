class Experiments::Achievement

  attr_reader :experiment, :subject_identifier, :label

  def initialize(experiment, subject_identifier, label)
    @experiment, @subject_identifier, @label = experiment, subject_identifier, label
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
      label:      label
    }
  end

  def to_json(options = {})
    as_json(options).to_json
  end
end

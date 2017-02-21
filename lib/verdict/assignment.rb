class Verdict::Assignment
  attr_reader :experiment, :subject, :group, :created_at

  def initialize(experiment, subject, group, originally_created_at, temporary = false)
    @experiment         = experiment
    @subject            = subject
    @group              = group
    @first              = originally_created_at.nil? || experiment.manual_assignment_timestamps?
    @created_at         = originally_created_at || Time.now.utc
    @temporary          = temporary
  end

  def qualified?
    !group.nil?
  end

  def permanent?
    !@temporary
  end

  def temporary?
    @temporary
  end

  def returning
    self.class.new(@experiment, @subject, @group, @created_at)
  end

  def returning?
    @first.nil?
  end

  def subject_identifier
    experiment.retrieve_subject_identifier(subject)
  end

  def handle
    qualified? ? group.handle : nil
  end

  def to_sym
    qualified? ? group.to_sym : nil
  end

  def as_json(options = {})
    {
      experiment: experiment.handle,
      subject:    subject_identifier,
      qualified:  qualified?,
      returning:  returning?,
      group:      qualified? ? group.handle : nil,
      created_at: created_at.utc.strftime('%FT%TZ')
    }
  end

  def to_json(options = {})
    as_json(options).to_json
  end

  def ===(other)
    case other
      when nil; !qualified?
      when Verdict::Assignment; other.group === group
      when Verdict::Group; other === group
      when Symbol, String; qualified? ? group.handle == other.to_s : false
      else false
    end
  end
end

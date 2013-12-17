class Verdict::Assignment

  attr_reader :experiment, :subject_identifier, :group, :created_at

  def initialize(experiment, subject_identifier, group, originally_created_at)
    @experiment         = experiment
    @subject_identifier = subject_identifier
    @group              = group
    @returning          = !originally_created_at.nil?
    @created_at         = originally_created_at || Time.now.utc
  end

  def subject
    @subject ||= experiment.fetch_subject(subject_identifier)
  end

  def qualified?
    !group.nil?
  end

  def returning
    self.class.new(@experiment, @subject_identifier, @group, @created_at)
  end

  def returning?
    @returning
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

class Verdict::Experiment

  include Verdict::Metadata

  attr_reader :handle, :qualifier, :subject_storage, :event_logger

  def self.define(handle, *args, &block)
    experiment = self.new(handle, *args, &block)
    raise Verdict::ExperimentHandleNotUnique.new(experiment.handle) if Verdict.repository.has_key?(experiment.handle)
    Verdict.repository[experiment.handle] = experiment
  end

  def initialize(handle, options = {}, &block)
    @handle = handle.to_s

    options = default_options.merge(options)
    @qualifier                   = options[:qualifier]
    @event_logger                = options[:event_logger] || Verdict::EventLogger.new(Verdict.default_logger)
    @subject_storage             = options[:storage] || Verdict::Storage::MemoryStorage.new
    @store_unqualified           = options[:store_unqualified]
    @segmenter                   = options[:segmenter]
    @subject_type                = options[:subject_type]
    @disqualify_empty_identifier = options[:disqualify_empty_identifier]

    instance_eval(&block) if block_given?
  end

  def subject_type(type = nil)
    return @subject_type if type.nil?
    @subject_type = type
  end

  def store_unqualified?
    @store_unqualified
  end

  def group(handle)
    segmenter.groups[handle.to_s]
  end

  def groups(segmenter_class = Verdict::FixedPercentageSegmenter, &block)
    return segmenter.groups unless block_given?
    @segmenter ||= segmenter_class.new(self)
    @segmenter.instance_eval(&block)
    @segmenter.verify!
    return self
  end

  def qualify(&block)
    @qualifier = block
  end

  def storage(subject_storage, options = {})
    @store_unqualified = options[:store_unqualified] if options.has_key?(:store_unqualified)
    @subject_storage = subject_storage
  end

  def segmenter
    raise Verdict::Error, "No groups defined for experiment #{@handle.inspect}." if @segmenter.nil?
    @segmenter
  end

  def started_at
    @started_at ||= @subject_storage.retrieve_start_timestamp(self)
  end

  def started?
    !@started_at.nil?
  end

  def group_handles
    segmenter.groups.keys
  end

  def subject_assignment(subject_identifier, group, originally_created_at = nil)
    Verdict::Assignment.new(self, subject_identifier, group, originally_created_at)
  end

  def subject_conversion(subject_identifier, goal, created_at = Time.now.utc)
    Verdict::Conversion.new(self, subject_identifier, goal, created_at)
  end

  def convert(subject, goal)
    identifier = retrieve_subject_identifier(subject)
    conversion = subject_conversion(identifier, goal)
    event_logger.log_conversion(conversion)
    segmenter.conversion_feedback(identifier, subject, conversion)
    conversion
  rescue Verdict::EmptySubjectIdentifier
    raise unless disqualify_empty_identifier?
  end

  def assign(subject, context = nil)
    identifier = retrieve_subject_identifier(subject)
    assignment = if store_unqualified?
      assignment_with_unqualified_persistence(identifier, subject, context)
    else
      assignment_without_unqualified_persistence(identifier, subject, context)
    end

    store_assignment(assignment)
  rescue Verdict::StorageError
    subject_assignment(identifier, nil, nil)
  rescue Verdict::EmptySubjectIdentifier
    if disqualify_empty_identifier?
      subject_assignment(identifier, nil, nil)
    else
      raise
    end
  end

  def disqualify_empty_identifier?
    @disqualify_empty_identifier
  end

  def disqualify(subject)
    identifier = retrieve_subject_identifier(subject)
    store_assignment(subject_assignment(identifier, nil, nil))
  end

  def store_assignment(assignment)
    @subject_storage.store_assignment(assignment) if should_store_assignment?(assignment)
    event_logger.log_assignment(assignment)
    assignment
  end

  def remove_subject(subject)
    remove_subject_identifier(retrieve_subject_identifier(subject))
  end

  def remove_subject_identifier(subject_identifier)
    @subject_storage.remove_assignment(self, subject_identifier)
  end

  def switch(subject, context = nil)
    assign(subject, context).to_sym
  end

  def lookup(subject)
    lookup_assignment_for_identifier(retrieve_subject_identifier(subject))
  end

  def lookup_assignment_for_identifier(subject_identifier)
    fetch_assignment(subject_identifier)
  end

  def wrapup
    @subject_storage.clear_experiment(self)
  end

  def retrieve_subject_identifier(subject)
    identifier = subject_identifier(subject).to_s
    raise Verdict::EmptySubjectIdentifier, "Subject resolved to an empty identifier!" if identifier.empty?
    identifier
  end

  def has_qualifier?
    !@qualifier.nil?
  end

  def everybody_qualifies?
    !has_qualifier?
  end

  def as_json(options = {})
    data = {
      handle: handle,
      has_qualifier: has_qualifier?,
      groups: segmenter.groups.values.map { |g| g.as_json(options) },
      metadata: metadata,
      started_at: started_at.nil? ? nil : started_at.utc.strftime('%FT%TZ')
    }

    data.tap do |data|
      data[:subject_type] = subject_type.to_s unless subject_type.nil?
    end
  end

  def to_json(options = {})
    as_json(options).to_json
  end 

  def fetch_subject(subject_identifier)
    raise NotImplementedError, "Fetching subjects based in identifier is not implemented for eperiment @{handle.inspect}."
  end

  def fetch_assignment(subject_identifier)
    @subject_storage.retrieve_assignment(self, subject_identifier)
  end

  protected

  def default_options
    {}
  end

  def should_store_assignment?(assignment)
    !assignment.returning? && (store_unqualified? || assignment.qualified?)
  end

  def assignment_with_unqualified_persistence(subject_identifier, subject, context)
    fetch_assignment(subject_identifier) || (
      subject_qualifies?(subject, context) ? 
        subject_assignment(subject_identifier, segmenter.assign(subject_identifier, subject, context), nil) :
        subject_assignment(subject_identifier, nil, nil)
    )
  end

  def assignment_without_unqualified_persistence(subject_identifier, subject, context)
    if subject_qualifies?(subject, context)
      fetch_assignment(subject_identifier) ||
        subject_assignment(subject_identifier, segmenter.assign(subject_identifier, subject, context), nil)
    else 
      subject_assignment(subject_identifier, nil, nil)
    end
  end  

  def subject_identifier(subject)
    subject.respond_to?(:id) ? subject.id : subject.to_s
  end

  def subject_qualifies?(subject, context = nil)
    ensure_experiment_has_started
    everybody_qualifies? || @qualifier.call(subject, context)
  end

  def set_start_timestamp
    @subject_storage.store_start_timestamp(self, started_now = Time.now.utc)
    started_now
  end

  def ensure_experiment_has_started
    @started_at ||= @subject_storage.retrieve_start_timestamp(self) || set_start_timestamp
  end
end

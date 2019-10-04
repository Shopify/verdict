class Verdict::Experiment

  include Verdict::Metadata

  attr_reader :handle, :qualifiers, :event_logger

  def self.define(handle, *args, &block)
    experiment = self.new(handle, *args, &block)
    raise Verdict::ExperimentHandleNotUnique.new(experiment.handle) if Verdict.repository.has_key?(experiment.handle)
    Verdict.repository[experiment.handle] = experiment
  end

  def initialize(handle, options = {}, &block)
    @started_at = nil
    @handle = handle.to_s

    options = default_options.merge(options)
    @qualifiers                   = Array(options[:qualifier] || options[:qualifiers])
    @event_logger                 = options[:event_logger] || Verdict::EventLogger.new(Verdict.default_logger)
    @storage                      = storage(options[:storage] || :memory)
    @store_unqualified            = options[:store_unqualified]
    @segmenter                    = options[:segmenter]
    @subject_type                 = options[:subject_type]
    @disqualify_empty_identifier  = options[:disqualify_empty_identifier]
    @manual_assignment_timestamps = options[:manual_assignment_timestamps]

    instance_eval(&block) if block_given?
  end

  def subject_type(type = nil)
    return @subject_type if type.nil?
    @subject_type = type
  end

  def store_unqualified?
    @store_unqualified
  end

  def manual_assignment_timestamps?
    @manual_assignment_timestamps
  end

  def group(handle)
    segmenter.groups[handle.to_s]
  end

  def groups(segmenter_class = Verdict::Segmenters::FixedPercentageSegmenter, &block)
    return segmenter.groups unless block_given?
    @segmenter ||= segmenter_class.new(self)
    @segmenter.instance_eval(&block)
    @segmenter.verify!
    return self
  end

  def rollout_percentage(percentage, rollout_group_name = :enabled)
    groups(Verdict::Segmenters::RolloutSegmenter) do
      group rollout_group_name, percentage
    end
  end

  def qualify(method_name = nil, &block)
    if block_given?
      @qualifiers << block
    elsif method_name.nil?
      raise ArgumentError, "no method nor blocked passed!"
    elsif respond_to?(method_name, true)
      @qualifiers << method(method_name).to_proc
    else
      raise ArgumentError, "No helper for #{method_name.inspect}"
    end
  end

  def storage(storage = nil, options = {})
    return @storage if storage.nil?

    @store_unqualified = options[:store_unqualified] if options.has_key?(:store_unqualified)
    @storage = case storage
      when :memory; Verdict::Storage::MemoryStorage.new
      when :none;   Verdict::Storage::MockStorage.new
      when Class;   storage.new
      else          storage
    end
  end

  def segmenter
    raise Verdict::Error, "No groups defined for experiment #{@handle.inspect}." if @segmenter.nil?
    @segmenter
  end

  def started_at
    @started_at ||= @storage.retrieve_start_timestamp(self)
  rescue Verdict::StorageError
    nil
  end

  def started?
    !@started_at.nil?
  end

  def group_handles
    segmenter.groups.keys
  end

  def subject_assignment(subject, group, originally_created_at = nil, temporary = false)
    Verdict::Assignment.new(self, subject, group, originally_created_at, temporary)
  end

  def subject_conversion(subject, goal, created_at = Time.now.utc)
    Verdict::Conversion.new(self, subject, goal, created_at)
  end

  def convert(subject, goal)
    identifier = retrieve_subject_identifier(subject)
    conversion = subject_conversion(subject, goal)
    event_logger.log_conversion(conversion)
    segmenter.conversion_feedback(identifier, subject, conversion)
    conversion
  rescue Verdict::EmptySubjectIdentifier
    raise unless disqualify_empty_identifier?
  end

  def assign(subject, context = nil)
    previous_assignment = lookup(subject)

    subject_identifier = retrieve_subject_identifier(subject)
    assignment = if previous_assignment
                   previous_assignment
                 elsif subject_qualifies?(subject, context)
                   group = segmenter.assign(subject_identifier, subject, context)
                   subject_assignment(subject, group, nil, group.nil?)
                 else
                   nil_assignment(subject)
                 end

    store_assignment(assignment)
  rescue Verdict::StorageError
    nil_assignment(subject)
  rescue Verdict::EmptySubjectIdentifier
    if disqualify_empty_identifier?
      nil_assignment(subject)
    else
      raise
    end
  end

  def assign_manually(subject, group)
    assignment = subject_assignment(subject, group)
    if !assignment.qualified? && !store_unqualified?
      raise Verdict::Error, "Unqualified subject assignments are not stored for this experiment, so manual disqualification is impossible. Consider setting :store_unqualified to true for this experiment."
    end

    store_assignment(assignment)
    assignment
  end

  def disqualify_manually(subject)
    assign_manually(subject, nil)
  end

  def store_assignment(assignment)
    @storage.store_assignment(assignment) if should_store_assignment?(assignment)
    event_logger.log_assignment(assignment)
    assignment
  end

  def cleanup(options = {})
    @storage.cleanup(self, options)
  end

  def remove_subject_assignment(subject)
    @storage.remove_assignment(self, subject)
  end

  def switch(subject, context = nil)
    assign(subject, context).to_sym
  end

  def lookup(subject)
    @storage.retrieve_assignment(self, subject)
  end

  def retrieve_subject_identifier(subject)
    identifier = subject_identifier(subject).to_s
    raise Verdict::EmptySubjectIdentifier, "Subject resolved to an empty identifier!" if identifier.empty?
    identifier
  end

  def has_qualifier?
    @qualifiers.any?
  end

  def everybody_qualifies?
    !has_qualifier?
  end

  def as_json(options = {})
    {
      handle: handle,
      has_qualifier: has_qualifier?,
      groups: segmenter.groups.values.map { |group| group.as_json(options) },
      metadata: metadata,
      started_at: started_at.nil? ? nil : started_at.utc.strftime('%FT%TZ')
    }.tap do |data|
      data[:subject_type] = subject_type.to_s unless subject_type.nil?
    end
  end

  def to_json(options = {})
    as_json(options).to_json
  end

  def fetch_subject(subject_identifier)
    raise NotImplementedError, "Fetching subjects based on identifier is not implemented for experiment #{@handle.inspect}."
  end

  def disqualify_empty_identifier?
    @disqualify_empty_identifier
  end

  def subject_qualifies?(subject, context = nil)
    ensure_experiment_has_started
    everybody_qualifies? || @qualifiers.all? { |qualifier| qualifier.call(subject, context) }
  end

  protected

  def default_options
    {}
  end

  def should_store_assignment?(assignment)
    assignment.permanent? && !assignment.returning? && (store_unqualified? || assignment.qualified?)
  end

  def subject_identifier(subject)
    subject.respond_to?(:id) ? subject.id : subject.to_s
  end

  def set_start_timestamp
    @storage.store_start_timestamp(self, started_now = Time.now.utc)
    started_now
  rescue NotImplementedError
    nil
  end

  def ensure_experiment_has_started
    @started_at ||= started_at || set_start_timestamp
  rescue Verdict::StorageError
    @started_at ||= Time.now.utc
  end

  def nil_assignment(subject)
    subject_assignment(subject, nil, nil)
  end
end

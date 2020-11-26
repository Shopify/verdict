require 'active_support'
require 'active_support/core_ext/class/attribute'
require 'active_support/core_ext/string/inflections'
require "verdict/storage"
class Verdict::Experiment

  include Verdict::Metadata

  class_attribute :qualifiers, default: []
  class_attribute :segmenter
  class_attribute :storage_instance, default: Verdict::Storage::MemoryStorage.new
  class_attribute :store_unqualified
  class_attribute :disqualify_empty_identifier, default: false
  class_attribute :manual_assignment_timestamps, default: false
  class_attribute :subject_type


  # Optional: Together with the "end_timestamp" and "stop_new_assignment_timestamp", limits the experiment run timeline within
  # the given time interval.
  #
  # Timestamps definitions:
  # start_timestamp: Experiment's start time. No assignments are made i.e. switch will return nil before this timestamp.
  # stop_new_assignment_timestamp: Experiment's new assignment stop time. No new assignments are made
  # i.e. switch returns nil for new assignments but the existing assignments are preserved.
  # end_timestamp: Experiment's end time. No assignments are made i.e. switch returns nil after this timestamp.
  #
  # Experiment run timeline:
  # start_timestamp -> (new assignments occur) -> stop_new_assignment_timestamp -> (no new assignments occur) -> end_timestamp
  class_attribute :schedule_start_timestamp
  class_attribute :schedule_end_timestamp
  class_attribute :schedule_stop_new_assignment_timestamp

  attr_reader :event_logger

  def self.qualify(method_name = nil, &block)
    if block_given?
      self.qualifiers += [block]
    elsif method_name
      self.qualifiers += [method_name.to_sym]
    else
      raise ArgumentError, "no method nor blocked passed!"
    end
  end

  def self.groups(segmenter_class = Verdict::Segmenters::FixedPercentageSegmenter, &block)
    self.segmenter ||= segmenter_class.new(self)
    segmenter.instance_eval(&block)
    segmenter.verify!
  end

  def self.storage(storage = nil, store_unqualified: false)
    return storage_instance if storage.nil?

    self.store_unqualified = store_unqualified
    self.storage_instance = case storage
      when :memory; Verdict::Storage::MemoryStorage.new
      when :none;   Verdict::Storage::MockStorage.new
      when Class;   storage.new
      else          storage
    end
  end

  def self.define(handle, *args, &block)
    experiment = self.new(handle, *args, &block)
    raise Verdict::ExperimentHandleNotUnique.new(experiment.handle) if Verdict.repository.has_key?(experiment.handle)
    Verdict.repository[experiment.handle] = experiment
  end

  def self.handle
    self.name.underscore
  end

  def initialize(handle = nil, options = {}, &block)
    @started_at = nil

    options = default_options.merge(options)
    @event_logger                 = options[:event_logger] || Verdict::EventLogger.new(Verdict.default_logger)

    instance_eval(&block) if block_given?
  end

  def storage
    self.class.storage_instance
  end

  def handle
    self.class.handle
  end

  def groups
    segmenter.groups
  end

  def group(handle)
    segmenter.groups[handle.to_s]
  end

  def rollout_percentage(percentage, rollout_group_name = :enabled)
    groups(Verdict::Segmenters::RolloutSegmenter) do
      group rollout_group_name, percentage
    end
  end

  def segmenter
    raise Verdict::Error, "No groups defined for experiment #{self.class.name}." if self.class.segmenter.nil?
    self.class.segmenter
  end

  def started_at
    @started_at ||= storage_instance.retrieve_start_timestamp(self)
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

  def assign(subject, context = nil, dynamic_qualifiers: [])
    previous_assignment = lookup(subject)

    assignment = if previous_assignment
      previous_assignment
    elsif dynamic_subject_qualifies?(subject, dynamic_qualifiers, context) && is_make_new_assignments?
      subject_identifier = retrieve_subject_identifier(subject)
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
    storage_instance.store_assignment(assignment) if should_store_assignment?(assignment)
    event_logger.log_assignment(assignment)
    assignment
  end

  def cleanup(options = {})
    storage_instance.cleanup(self, options)
  end

  def remove_subject_assignment(subject)
    storage_instance.remove_assignment(self, subject)
  end

  # The qualifiers param accepts an array of procs.
  # This is intended for qualification logic that cannot be defined in the experiment definition
  def switch(subject, context = nil, qualifiers: [])
    return unless is_scheduled?
    assign(subject, context, dynamic_qualifiers: qualifiers).to_sym
  end

  def lookup(subject)
    storage_instance.retrieve_assignment(self, subject)
  end

  def retrieve_subject_identifier(subject)
    identifier = subject_identifier(subject).to_s
    raise Verdict::EmptySubjectIdentifier, "Subject resolved to an empty identifier!" if identifier.empty?
    identifier
  end

  def has_qualifier?
    qualifiers.any?
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

  def subject_qualifies?(subject, context = nil, dynamic_qualifiers: [])
    ensure_experiment_has_started
    return false unless dynamic_qualifiers.all? { |qualifier| qualifier.call(subject) }
    everybody_qualifies? || all_qualifiers_satisfied_for?(subject, context)
  end


  def all_qualifiers_satisfied_for?(subject, context)
    qualifiers.all? do |qualifier|
      case qualifier
      when Symbol
        send(qualifier, subject, context)
      else
        instance_exec(subject, context, &qualifier)
      end
    end
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
    storage_instance.store_start_timestamp(self, started_now = Time.now.utc)
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

  private

  def is_scheduled?
    if schedule_start_timestamp? && schedule_start_timestamp > Time.now
      false
    elsif schedule_end_timestamp? && schedule_end_timestamp <= Time.now
      false
    else
      true
    end
  end

  def is_make_new_assignments?
    return !(schedule_stop_new_assignment_timestamp? && schedule_stop_new_assignment_timestamp <= Time.now)
  end

  # Used when a Experiment class has overridden the subject_qualifies? method prior to v0.15.0
  # The previous version of subject_qualifies did not accept dynamic qualifiers, thus this is used to
  # determine how many parameters to pass
  def dynamic_subject_qualifies?(subject, dynamic_qualifiers, context)
    if method(:subject_qualifies?).parameters.include?([:key, :dynamic_qualifiers])
      subject_qualifies?(subject, context, dynamic_qualifiers: dynamic_qualifiers)
    else
      subject_qualifies?(subject, context)
    end
  end
end

class Experiments::Experiment

  include Experiments::Metadata

  attr_reader :handle, :qualifier, :subject_storage

  def self.define(handle, *args, &block)
    experiment = self.new(handle, *args, &block)
    raise Experiments::ExperimentHandleNotUnique.new(experiment.handle) if Experiments.repository.has_key?(experiment.handle)
    Experiments.repository[experiment.handle] = experiment
  end

  def initialize(handle, options = {}, &block)
    @handle = handle.to_s

    options = default_options.merge(options)
    @qualifier         = options[:qualifier]
    @subject_storage   = options[:storage]
    @store_unqualified = options[:store_unqualified]
    @segmenter         = options[:segmenter]
    @subject_type      = options[:subject_type]
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

  def groups(segmenter_class = Experiments::Segmenter::StaticPercentage, &block)
    return @segmenter.groups unless block_given?
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
    raise Experiments::Error, "No groups defined for experiment #{@handle.inspect}." if @segmenter.nil?
    @segmenter
  end

  def group_handles
    segmenter.groups.keys
  end

  def subject_assignment(subject_identifier, group, returning = true)
    Experiments::Assignment.new(self, subject_identifier, group, returning)
  end

  def assign(subject, context = nil)
    identifier = retrieve_subject_identifier(subject)
    assignment = if store_unqualified?
      assignment_with_unqualified_persistence(identifier, subject, context)
    else
      assignment_without_unqualified_persistence(identifier, subject, context)
    end

    @subject_storage.store_assignment(assignment) if should_store_assignment?(assignment)
    log_assignment(assignment)
    assignment
  rescue Experiments::StorageError
    subject_assignment(identifier, nil, false)
  end

  def switch(subject, context = nil)
    assign(subject, context).to_sym
  end

  def retrieve_subject_identifier(subject)
    identifier = subject_identifier(subject).to_s
    raise Experiments::EmptySubjectIdentifier, "Subject resolved to an empty identifier!" if identifier.empty?
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
      metadata: metadata
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

  protected

  def default_options
    {
      storage: Experiments::Storage::Dummy.new
    }
  end

  def should_store_assignment?(assignment)
    !assignment.returning? && (store_unqualified? || assignment.qualified?)
  end

  def assignment_with_unqualified_persistence(subject_identifier, subject, context)
    @subject_storage.retrieve_assignment(self, subject_identifier) || (
      subject_qualifies?(subject, context) ? 
        subject_assignment(subject_identifier, @segmenter.assign(subject_identifier, subject, context), false) :
        subject_assignment(subject_identifier, nil, false)
    )
  end

  def assignment_without_unqualified_persistence(subject_identifier, subject, context)
    if subject_qualifies?(subject, context)
      @subject_storage.retrieve_assignment(self, subject_identifier) ||
        subject_assignment(subject_identifier, @segmenter.assign(subject_identifier, subject, context), false)
    else 
      subject_assignment(subject_identifier, nil, false)
    end
  end  

  def log_assignment(assignment)
    status = assignment.returning? ? 'returning' : 'new'
    if assignment.qualified?
      Experiments.logger.info "[Experiments] experiment=#{assignment.experiment.handle} subject=#{assignment.subject_identifier} status=#{status} qualified=true group=#{assignment.group.handle}"
    else
      Experiments.logger.info "[Experiments] experiment=#{assignment.experiment.handle} subject=#{assignment.subject_identifier} status=#{status} qualified=false"
    end
  end

  def subject_identifier(subject)
    subject.respond_to?(:id) ? subject.id : subject.to_s
  end

  def subject_qualifies?(subject, context = nil)
    everybody_qualifies? || @qualifier.call(subject, context)
  end
end

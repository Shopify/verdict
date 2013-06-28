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

    @qualifier ||= options[:qualifier] || create_qualifier
    @subject_storage = options[:storage] || create_subject_store
    @store_unqualified = options[:store_unqualified]
    @segmenter = options[:segmenter]

    instance_eval(&block) if block_given?
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

  def create_assignment(group, returning = true)
    Experiments::Assignment.new(self, group, returning)
  end

  def assign(subject, context = nil)
    identifier = retrieve_subject_identifier(subject)
    assignment = if store_unqualified?
      assignment_with_unqualified_persistence(identifier, subject, context)
    else
      assignment_without_unqualified_persistence(identifier, subject, context)
    end

    log_assignment(identifier, assignment)
    @subject_storage.store_assignment(self, identifier, assignment) if should_store_assignment?(assignment)
    
    assignment
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
    {
      handle: handle,
      has_qualifier: has_qualifier?,
      groups: segmenter.groups.values.map { |g| g.as_json(options) },
      metadata: metadata
    }
  end

  def to_json(options = {})
    as_json(options).to_json
  end  

  protected

  def should_store_assignment?(assignment)
    !assignment.returning? && (store_unqualified? || assignment.qualified?)
  end

  def assignment_with_unqualified_persistence(identifier, subject, context)
    @subject_storage.retrieve_assignment(self, identifier) || (
      subject_qualifies?(subject, context) ? 
        create_assignment(@segmenter.assign(identifier, subject, context), false) :
        create_assignment(nil, false)
    )
  end

  def assignment_without_unqualified_persistence(identifier, subject, context)
    if subject_qualifies?(subject, context)
      @subject_storage.retrieve_assignment(self, identifier) ||
        create_assignment(@segmenter.assign(identifier, subject, context), false)
    else 
      create_assignment(nil, false)
    end
  end  

  def log_assignment(identifier, assignment)
    status = assignment.returning? ? 'returning' : 'new'
    if assignment.qualified?
      Experiments.logger.info "[Experiments] experiment=#{@handle} subject=#{identifier} status=#{status} qualified=true group=#{assignment.group.handle}"
    else
      Experiments.logger.info "[Experiments] experiment=#{@handle} subject=#{identifier} status=#{status} qualified=false"
    end
  end

  def subject_identifier(subject)
    subject.respond_to?(:id) ? subject.id : subject.to_s
  end

  def subject_qualifies?(subject, context = nil)
    everybody_qualifies? || @qualifier.call(subject, context)
  end

  def create_qualifier
    nil
  end

  def create_subject_store
    Experiments::Storage::Dummy.new
  end
end

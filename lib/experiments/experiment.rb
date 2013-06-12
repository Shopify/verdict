class Experiments::Experiment

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
    @segmenter = options[:segmenter]

    instance_eval(&block) if block_given?
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

  def storage(subject_storage)
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
    identifier = subject_identifier(subject)
    assignment = @subject_storage.retrieve_assignment(self, identifier) || assignment_for_subject(identifier, subject, context)
    
    status = assignment.returning? ? 'returning' : 'new'
    if assignment.qualified?
      Experiments.logger.info "[Experiments] experiment=#{@handle} subject=#{identifier} status=#{status} qualified=true group=#{assignment.group.handle}"
    else
      Experiments.logger.info "[Experiments] experiment=#{@handle} subject=#{identifier} status=#{status} qualified=false"
    end
    assignment
  end

  def switch(subject, context = nil)
    assign(subject, context).to_sym
  end

  def subject_identifier(subject)
    subject.respond_to?(:id) ? subject.id.to_s : subject.to_s
  end

  protected

  def assignment_for_subject(identifier, subject, context)
    assignment = if @qualifier.call(subject, context)
      group = @segmenter.assign(identifier, subject, context)
      create_assignment(group, false)
    else
      create_assignment(nil, false)
    end
    @subject_storage.store_assignment(self, identifier, assignment)
    assignment
  end

  def create_qualifier
    lambda { |_, _| true }    
  end

  def create_subject_store
    Experiments::Storage::Dummy.new
  end
end

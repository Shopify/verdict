class Experiments::Experiment

  attr_reader :name, :qualifier, :subject_storage

  def self.define(name, *args, &block)
    experiment = self.new(name, *args, &block)
    raise Experiments::ExperimentNameNotUnique.new(experiment.name) if Experiments.repository.has_key?(experiment.name)
    Experiments.repository[experiment.name] = experiment
  end

  def initialize(name, options = {}, &block)
    @name = name.to_s

    @qualifier ||= options[:qualifier] || create_qualifier
    @subject_storage = options[:storage] || create_subject_store
    @segmenter = options[:segmenter]

    instance_eval(&block) if block_given?
  end

  def group(name)
    segmenter.groups[name.to_s]
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
    raise Experiments::Error, "No groups defined for experiment #{@name.inspect}." if @segmenter.nil?
    @segmenter
  end

  def group_labels
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
      Experiments.logger.info "[Experiments] experiment=#{@name} subject=#{identifier} status=#{status} qualified=true group=#{assignment.group.label}"
    else
      Experiments.logger.info "[Experiments] experiment=#{@name} subject=#{identifier} status=#{status} qualified=false"
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

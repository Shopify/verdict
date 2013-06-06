class Experiments::Experiment

  attr_reader :name, :qualifier, :segmenter, :subject_storage

  def initialize(name, options = {}, &block)
    @name = name.to_s
    raise Experiments::ExperimentNameNotUnique.new(@name) if Experiments.repository.has_key?(@name)
    Experiments.repository[@name] = self

    @qualifier = options[:qualifier] || create_qualifier
    @subject_storage = options[:storage] || create_subject_store
    @segmenter = options[:segmenter]

    instance_eval(&block) if block_given?
  end

  def groups(segmenter_class = Experiments::Segmenter::StaticPercentage, &block)
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

  def assign(subject, context = nil)
    identifier = subject_identifier(subject)
    assignment = @subject_storage.get(@name, identifier) || assignment_for_subject(identifier, subject, context)
    
    status = assignment[:new] ? 'new' : 'returning'
    if assignment[:qualified]
      group = assignment[:group]
      Experiments.logger.info "[Experiments] experiment=#{@name} subject=#{identifier} status=#{status} qualified=true group=#{group}"
      group
    else
      Experiments.logger.info "[Experiments] experiment=#{@name} subject=#{identifier} status=#{status} qualified=false"
      nil        
    end
  end

  def subject_identifier(subject)
    subject.respond_to?(:id) ? subject.id.to_s : subject.to_s
  end

  protected

  def assignment_for_subject(identifier, subject, context)
    if @qualifier.call(subject, context)
      segment = @segmenter.assign(identifier, subject, context)
      @subject_storage.set(@name, identifier, true, segment)
      { :qualified => true, :group => segment, :new => true }
    else
      @subject_storage.set(@name, identifier, false, nil)
      { :qualified => false, :new => true }
    end
  end

  def create_qualifier
    lambda { |_, _| true }    
  end

  def create_subject_store
    Experiments::Storage::Dummy.new
  end
end

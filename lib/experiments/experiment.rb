class Experiments::Experiment
  
  attr_reader :name, :qualifier, :segmenter

  def initialize(name, options = {}, &block)
    @name = name
    @qualifier = options[:qualifier] || lambda { |_, _| true }
    @segmenter = options[:segmenter] || Experiments::Segmenter::StaticPercentage.new(self)
    @store     = options[:store]     || Experiments::SubjectStore::Dummy.new
    yield @segmenter if block_given?
    @segmenter.verify!
  end

  def segments
    @segmenter.segments
  end

  def segment_for(subject, context = nil)
    identifier = subject_identifier(subject)
    if stored_subject = @store.get(@name, identifier)
      store_hit(identifier, stored_subject)
    else 
      store_miss(identifier, subject, context)
    end
  end

  alias_method :group_for, :segment_for

  def subject_identifier(subject)
    subject.respond_to?(:id) ? subject.id.to_s : subject.to_s
  end


  protected


  def store_hit(identifier, stored_subject)
    if stored_subject[:qualified]
      segment = stored_subject[:segment]
      Experiments.logger.info "[Experiment #{@name}] subject ID #{identifier.inspect} is in segment #{segment.inspect}."
      return segment
    else
      Experiments.logger.info "[Experiment #{@name}] subject ID #{identifier.inspect} is not qualified."
      return nil        
    end
  end

  def store_miss(identifier, subject, context)
    if @qualifier.call(subject, context)
      segment = @segmenter.segment(identifier, subject, context)
      @store.set(@name, identifier, true, segment)
      Experiments.logger.info "[Experiment #{@name}] subject ID #{identifier.inspect} (new) is in segment #{segment.inspect}."
      return segment
    else
      Experiments.logger.info "[Experiment #{@name}] subject ID #{identifier.inspect} (new) is not qualified."
      @store.set(@name, identifier, false, nil)
      return nil
    end
  end
end

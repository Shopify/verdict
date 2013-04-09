class Experiments::Experiment
  
  attr_reader :name, :qualifier, :segmenter

  def initialize(name, options = {}, &block)
    @name = name
    @qualifier = options[:qualifier] || lambda { |_, _| true }
    @segmenter = options[:segmenter] || Experiments::Segmenter::StaticPercentage.new(self)
    yield @segmenter if block_given?
    @segmenter.verify!
  end

  def segments
    @segmenter.segments
  end

  def segment_for(subject, context = nil)
    identifier = subject_identifier(subject)
    if @qualifier.call(subject, context)
      segment = @segmenter.segment(identifier, subject, context)
      Experiments.logger.info "[Experiment #{@name}] subject ID #{identifier.inspect} is in segment #{segment.inspect}."
      segment
    else
      Experiments.logger.info "[Experiment #{@name}] subject ID #{identifier.inspect} is not qualified."
      nil
    end
  end

  alias_method :group_for, :segment_for

  def subject_identifier(subject)
    subject.respond_to?(:id) ? subject.id.to_s : subject.to_s
  end
end

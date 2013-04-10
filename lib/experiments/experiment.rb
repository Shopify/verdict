class Experiments::Experiment
  
  attr_reader :name, :qualifier, :segmenter

  def initialize(name, options = {}, &block)
    @name = name
    @qualifier = options[:qualifier] || lambda { |_, _| true }
    @segmenter = options[:segmenter] || Experiments::Segmenter::StaticPercentage.new(self)
    @segmentation_store = options[:store] || Experiments::SubjectStore::Dummy.new
    yield @segmenter if block_given?
    @segmenter.verify!
  end

  def segments
    @segmenter.segments
  end

  def segment_for(subject, context = nil)
    identifier = subject_identifier(subject)
    segmentation = @segmentation_store.get(@name, identifier) || segmentation_for_subject(identifier, subject, context)
    
    status = segmentation[:new] ? 'new' : 'returning'
    if segmentation[:qualified]
      segment = segmentation[:segment]
      Experiments.logger.info "[Experiments] experiment=#{@name} subject=#{identifier} status=#{status} qualified=true segment=#{segment}"
      segment
    else
      Experiments.logger.info "[Experiments] experiment=#{@name} subject=#{identifier} status=#{status} qualified=false"
      nil        
    end
  end

  alias_method :group_for, :segment_for

  def subject_identifier(subject)
    subject.respond_to?(:id) ? subject.id.to_s : subject.to_s
  end

  protected

  def segmentation_for_subject(identifier, subject, context)
    if @qualifier.call(subject, context)
      segment = @segmenter.segment(identifier, subject, context)
      @segmentation_store.set(@name, identifier, true, segment)
      { :qualified => true, :segment => segment, :new => true }
    else
      @segmentation_store.set(@name, identifier, false, nil)
      { :qualified => false, :new => true }
    end
  end
end

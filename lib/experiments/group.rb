class Experiments::Group
  include Experiments::Metadata

  attr_reader :experiment, :handle

  def initialize(experiment, handle)
    @experiment, @handle = experiment, handle.to_s
  end

  def to_s
    handle
  end

  def to_sym
    handle.to_sym
  end

  def ===(other)
    case other
      when Experiments::Group; experiment == other.experiment && other.handle == handle
      when Symbol, String; handle == other.to_s
      else false
    end
  end

  def as_json(options = {})
    {
      handle: handle,
      metadata: metadata
    }
  end

  def to_json(options = {})
    as_json(options).to_json
  end
end

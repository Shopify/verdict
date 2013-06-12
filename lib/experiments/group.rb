class Experiments::Group

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
end

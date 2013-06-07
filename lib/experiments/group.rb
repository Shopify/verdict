class Experiments::Group

  attr_reader :experiment, :label

  def initialize(experiment, label)
    @experiment, @label = experiment, label.to_s
  end

  def to_s
    label
  end

  def to_sym
    label.to_sym
  end

  def ===(other)
    case other
      when Experiments::Group; experiment == other.experiment && other.label == label
      when Symbol, String; label == other.to_s
      else false
    end
  end
end

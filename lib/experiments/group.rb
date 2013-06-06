class Experiments::Group

  attr_reader :experiment, :label

  def initialize(experiment, label)
    @label = label
  end

  def to_s
    label
  end

  def ===(other)
    case other
      when Experiments::Group; other.label.to_s == label.to_s
      when Symbol, String; label.to_s == other.to_s
      else false
    end
  end
end

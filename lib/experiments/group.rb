class Experiments::Group

  attr_reader :label, :options

  def initialize(label)
    @label = label
  end

  def to_s
    label
  end
end

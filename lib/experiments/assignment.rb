class Experiments::Assignment

  attr_reader :experiment, :group

  def initialize(experiment, group = nil, returning = true)
    @experiment = experiment
    @returning  = returning
    @group      = group
  end

  def qualified?
    !group.nil?
  end

  def returning
    self.class.new(@experiment, @group, true)
  end

  def returning?
    @returning
  end

  def to_sym
    qualified? ? group.to_sym : nil
  end  

  def ===(other)
    case other
      when nil; !qualified?
      when Experiments::Assignment; other.group === group
      when Experiments::Group; other === group
      when Symbol, String; qualified? ? group.label.to_s == other.to_s : false
      else false
    end
  end
end

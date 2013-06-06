class Experiments::Assignment

  attr_writer :qualified, :returning, :group

  def initialize(options = {})
    @qualified = options[:qualified]
    @returning = options[:returning]
    @group     = options[:group]
  end

  def group
    @group
  end

  def qualified?
    @qualified
  end

  def returning?
    @returning
  end
end

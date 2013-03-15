class ShopExperiment < Experiment
  class_attribute :all
  self.all = []

  def initialize(name, &block)
    super

    ShopExperiment.all << self
  end
end

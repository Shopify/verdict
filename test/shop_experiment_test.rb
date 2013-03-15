require "test_helper"

class ShopExperimentTest < ActiveSupport::TestCase
  
  def test_new_instance_adds_its_self_to_collection
    ShopExperiment.all = []
    
    experiment = ShopExperiment.new('pie_shop') do |group|
      group.half :cherry
      group.half :apple
    end
    
    assert_equal [experiment], ShopExperiment.all
  end
  
end

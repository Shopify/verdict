require 'test_helper'

class MemorySubjectStorageTest < MiniTest::Unit::TestCase

  def setup
    @storage = storage = Experiments::Storage::MemoryStorage.new
    @experiment = Experiments::Experiment.new(:redis_storage) do
      groups { group :all, 100 }
      storage storage, store_unqualified: true
    end

    @subject = stub(id: 'bootscale')
  end

  def test_wrapup
    @experiment.assign(@subject)
    @experiment.wrapup
    assert @experiment.lookup(@subject).nil?
  end

  def test_with_memory_store
    assignment_1 = @experiment.assign(@subject)
    assignment_2 = @experiment.assign(@subject)
    assert !assignment_1.returning?
    assert assignment_2.returning?
  end

  def test_assignment_lookup
    assert @experiment.lookup(@subject).nil?
    @experiment.assign(@subject)
    assert !@experiment.lookup(@subject).nil?
  end

  def test_remove_assignment
    assert !@experiment.assign(@subject).returning?
    @experiment.wrapup
    assert !@experiment.assign(@subject).returning?
  end

  def test_started_at
    assert @storage.start_timestamps[@experiment.handle].nil?
    @experiment.started_at
    assert @storage.start_timestamps[@experiment.handle].instance_of?(DateTime)
  end
end

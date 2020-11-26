require 'test_helper'

class MemoryStorageTest < Minitest::Test
  class MemoryStorage < Verdict::Experiment
    groups { group :all, 100 }
  end

  def setup
    @storage = Verdict::Storage::MemoryStorage.new

    @experiment = MemoryStorage.new

    @subject = stub(id: 'bootscale')
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
    assignment = @experiment.assign(@subject)
    assert !assignment.returning?

    assert @experiment.assign(@subject).returning?
    @storage.remove_assignment(@experiment, @subject.id)
    assert !@experiment.assign(@subject).returning?
  end

  def test_started_at
    assert @storage.send(:get, @experiment.handle.to_s, 'started_at').nil?
    @experiment.send(:ensure_experiment_has_started)
    refute @storage.send(:get, @experiment.handle.to_s, 'started_at').nil?
    assert_instance_of Time, @experiment.started_at
  end
end

require 'test_helper'

class RedisSubjectStorageTest < MiniTest::Unit::TestCase

  def setup
    @redis = ::Redis.new(host: REDIS_HOST, port: REDIS_PORT)
    @storage = storage = Experiments::Storage::RedisStorage.new(@redis)
    @experiment = Experiments::Experiment.new(:redis_storage) do
      qualify { |s| s == 'subject_1' }
      groups { group :all, 100 }
      storage storage, store_unqualified: true
    end
  end

  def teardown
    @redis.del('experiments/redis_storage')
  end

  def test_generate_experiment_key_should_generate_namespaced_key
    assert_equal 'experiments/redis_storage', @storage.send(:generate_experiment_key, @experiment)
  end

  def test_store_and_retrieve_qualified_assignment
    experiment_key = @storage.send(:generate_experiment_key, @experiment)
    assert !@redis.hexists(experiment_key, 'subject_1')

    new_assignment = @experiment.assign('subject_1')
    assert new_assignment.qualified?
    assert !new_assignment.returning?

    assert @redis.hexists(experiment_key, 'subject_1')

    returning_assignment = @experiment.assign('subject_1')
    assert returning_assignment.returning?
    assert_equal new_assignment.experiment, returning_assignment.experiment
    assert_equal new_assignment.group, returning_assignment.group
  end

  def test_store_and_retrieve_unqualified_assignment
    experiment_key = @storage.send(:generate_experiment_key, @experiment)
    assert !@redis.hexists(experiment_key, 'subject_2')

    new_assignment = @experiment.assign('subject_2')

    assert !new_assignment.returning?
    assert !new_assignment.qualified?
    assert @redis.hexists(experiment_key, 'subject_2')

    returning_assignment = @experiment.assign('subject_2')
    assert returning_assignment.returning?
    assert_equal new_assignment.experiment, returning_assignment.experiment
    assert_equal new_assignment.group, returning_assignment.group
  end

  def test_assign_should_return_unqualified_when_redis_is_unavailable_for_reads
    @redis.stubs(:hget).raises(::Redis::BaseError, "Redis is down")
    assert !@experiment.assign('subject_1').qualified?
  end

  def test_assign_should_return_unqualified_when_redis_is_unavailable_for_writes
    @redis.stubs(:hset).raises(::Redis::BaseError, "Redis is down")
    assert !@experiment.assign('subject_1').qualified?
  end

  def test_remove_assignment
    experiment_key = @storage.send(:generate_experiment_key, @experiment)
    @experiment.assign('subject_3')
    assert @redis.hexists(experiment_key, 'subject_3')
    @experiment.remove_subject('subject_3')
    assert !@redis.hexists(experiment_key, 'subject_3')
  end

  def test_clear_experiment
    experiment_key = @storage.send(:generate_experiment_key, @experiment)
    new_assignment = @experiment.assign('subject_3')
    assert @redis.exists(experiment_key)
    @experiment.wrapup
    assert !@redis.exists(experiment_key)
  end
end

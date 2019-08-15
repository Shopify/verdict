require 'test_helper'

class RedisStorageTest < Minitest::Test

  def setup
    @redis = ::Redis.new(host: REDIS_HOST, port: REDIS_PORT)
    @storage = storage = Verdict::Storage::RedisStorage.new(@redis)
    @experiment = Verdict::Experiment.new(:redis_storage) do
      qualify { |s| s == 'subject_1' }
      groups { group :all, 100 }
      storage storage, store_unqualified: true
    end
  end

  def teardown
    @redis.del('experiments/redis_storage')
  end

  def test_store_and_retrieve_qualified_assignment
    refute @redis.hexists(experiment_key, 'assignment_subject_1')

    new_assignment = @experiment.assign('subject_1')
    assert new_assignment.qualified?
    refute new_assignment.returning?

    assert @redis.hexists(experiment_key, 'assignment_subject_1')

    returning_assignment = @experiment.assign('subject_1')
    assert returning_assignment.returning?
    assert_equal new_assignment.experiment, returning_assignment.experiment
    assert_equal new_assignment.group, returning_assignment.group
  end

  def test_store_and_retrieve_unqualified_assignment
    refute @redis.hexists(experiment_key, 'assignment_subject_2')

    new_assignment = @experiment.assign('subject_2')

    refute new_assignment.returning?
    refute new_assignment.qualified?
    assert @redis.hexists(experiment_key, 'assignment_subject_2')

    returning_assignment = @experiment.assign('subject_2')
    assert returning_assignment.returning?
    assert_equal new_assignment.experiment, returning_assignment.experiment
    assert_nil new_assignment.group
    assert_nil returning_assignment.group
  end

  def test_assign_should_return_unqualified_when_redis_is_unavailable_for_reads
    @redis.stubs(:hget).raises(::Redis::BaseError, "Redis is down")
    assert !@experiment.assign('subject_1').qualified?
  end

  def test_assign_should_return_unqualified_when_redis_is_unavailable_for_writes
    @redis.stubs(:hset).raises(::Redis::BaseError, "Redis is down")
    assert !@experiment.assign('subject_1').qualified?
  end

  def test_remove_subject_assignment
    @experiment.assign('subject_3')
    assert @redis.hexists(experiment_key, 'assignment_subject_3')
    @experiment.remove_subject_assignment('subject_3')
    refute @redis.hexists(experiment_key, 'assignment_subject_3')
  end

  def test_started_at
    refute @redis.hexists(experiment_key, "started_at")
    a = @experiment.send(:ensure_experiment_has_started)
    assert @redis.hexists(experiment_key, "started_at")
    assert_equal a, @experiment.started_at
  end

  def test_cleanup
    1000.times do |n|
      @experiment.assign("something_#{n}")
    end

    assert_operator @redis, :exists, experiment_key

    @storage.cleanup(:redis_storage)
    refute_operator @redis, :exists, experiment_key
  end

  private

  def experiment_key
    "experiments/redis_storage"
  end
end

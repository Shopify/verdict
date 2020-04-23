require 'json'
require 'test_helper'

class ExperimentTest < Minitest::Test

  def test_no_qualifier
    e = Verdict::Experiment.new('test')
    refute e.has_qualifier?
    assert e.everybody_qualifies?
  end

  def test_qualifier
    e = Verdict::Experiment.new('test') do |experiment|
      qualify { |subject| subject.country == 'CA' }
      groups do
        group :all, 100
      end
    end

    assert e.has_qualifier?
    refute e.everybody_qualifies?

    subject_stub = Struct.new(:id, :country)
    ca_subject = subject_stub.new(1, 'CA')
    us_subject = subject_stub.new(2, 'US')

    assert e.qualifiers.all? { |q| q.call(ca_subject) }
    refute e.qualifiers.all? { |q| q.call(us_subject) }

    qualified = e.assign(ca_subject)
    assert_kind_of Verdict::Assignment, qualified
    assert_equal e.group(:all), qualified.group

    non_qualified = e.assign(us_subject)
    assert_kind_of Verdict::Assignment, non_qualified
    refute non_qualified.qualified?
    assert_nil non_qualified.group
  end

  def test_multiple_qualifier
    e = Verdict::Experiment.new('test') do |experiment|
      qualify { |subject| subject.language == 'fr' }
      qualify { |subject| subject.country == 'CA' }

      groups do
        group :all, 100
      end
    end

    assert e.has_qualifier?
    refute e.everybody_qualifies?

    subject_stub = Struct.new(:id, :country, :language)
    fr_subject = subject_stub.new(1, 'CA', 'fr')
    en_subject = subject_stub.new(2, 'CA', 'en')

    assert e.qualifiers.all? { |q| q.call(fr_subject) }
    refute e.qualifiers.all? { |q| q.call(en_subject) }

    qualified = e.assign(fr_subject)
    assert_kind_of Verdict::Assignment, qualified
    assert_equal e.group(:all), qualified.group

    non_qualified = e.assign(en_subject)
    assert_kind_of Verdict::Assignment, non_qualified
    refute non_qualified.qualified?
    assert_nil non_qualified.group
  end

  module CountryIsCanadaHelper
    def country_is_canada(subject, _context)
      subject.country == 'CA'
    end
  end
  def test_method_qualifier

    e = Verdict::Experiment.new('test') do |experiment|
      extend CountryIsCanadaHelper

      qualify :country_is_canada

      groups do
        group :all, 100
      end
    end

    assert e.has_qualifier?
    refute e.everybody_qualifies?

    subject_stub = Struct.new(:id, :country)
    ca_subject = subject_stub.new(1, 'CA')
    us_subject = subject_stub.new(2, 'US')

    assert e.qualifiers.all? { |q| q.call(ca_subject, nil) }
    refute e.qualifiers.all? { |q| q.call(us_subject, nil) }

    qualified = e.assign(ca_subject)
    assert_kind_of Verdict::Assignment, qualified
    assert_equal e.group(:all), qualified.group

    non_qualified = e.assign(us_subject)
    assert_kind_of Verdict::Assignment, non_qualified
    refute non_qualified.qualified?
    assert_nil non_qualified.group
  end

  def test_disqualify_empty_identifier
    e = Verdict::Experiment.new('test', disqualify_empty_identifier: true) do
      groups do
        group :a, :half
        group :b, :rest
      end
    end

    refute e.assign(nil).qualified?
    assert_nil e.convert('', :mygoal)
  end

  def test_assignment
    e = Verdict::Experiment.new('test') do
      qualify { |subject| subject <= 2 }
      groups do
        group :a, :half
        group :b, :rest
      end
    end

    assert_raises(Verdict::EmptySubjectIdentifier) { e.assign(nil) }

    assignment = e.assign(1)
    assert_kind_of Verdict::Assignment, assignment
    assert assignment.qualified?
    refute assignment.returning?
    assert_equal assignment.group, e.group(:a)

    assignment = e.assign(3)
    assert_kind_of Verdict::Assignment, assignment
    refute assignment.qualified?

    assert_equal :a,  e.switch(1)
    assert_equal :b,  e.switch(2)
    assert_nil e.switch(3)
  end

  def test_experiment_without_manual_assignment_timestamps_option
    e = Verdict::Experiment.new('test') do
      groups { group :all, 100 }
    end

    refute e.manual_assignment_timestamps?
  end

  def test_experiment_with_manual_assignment_timestamps_option
    e = Verdict::Experiment.new('test', manual_assignment_timestamps: true) do
      groups { group :all, 100 }
    end

    assert e.manual_assignment_timestamps?
  end

  def test_subject_identifier
    e = Verdict::Experiment.new('test')
    assert_equal '123', e.retrieve_subject_identifier(stub(id: 123, to_s: '456'))
    assert_equal '456', e.retrieve_subject_identifier(stub(to_s: '456'))
    assert_raises(Verdict::EmptySubjectIdentifier) { e.retrieve_subject_identifier(stub(id: nil)) }
    assert_raises(Verdict::EmptySubjectIdentifier) { e.retrieve_subject_identifier(stub(to_s: '')) }
  end

  def test_assignment_without_store_unqualified_always_fetches_old_assignment_if_available
    mock_store, mock_qualifier = Verdict::Storage::MockStorage.new, mock('qualifier')
    e = Verdict::Experiment.new('test') do
      qualify { mock_qualifier.qualifies? }
      storage mock_store, store_unqualified: false
      groups { group :all, 100 }
    end

    qualified_assignment = e.subject_assignment(mock('identifier'), e.group(:all), Time.now)

    mock_store.expects(:retrieve_assignment).returns(qualified_assignment).once
    mock_store.expects(:store_assignment).never
    e.assign(mock('subject'))
  end

  def test_new_unqualified_assignment_without_store_unqualified_does_not_store_if_merchant_not_qualified
    mock_store, mock_qualifier = Verdict::Storage::MockStorage.new, mock('qualifier')
    e = Verdict::Experiment.new('test') do
      qualify { mock_qualifier.qualifies? }
      storage mock_store, store_unqualified: false
      groups { group :all, 100 }
    end

    mock_qualifier.expects(:qualifies?).returns(false)
    mock_store.expects(:retrieve_assignment).returns(nil).once
    mock_store.expects(:store_assignment).never
    e.assign(mock('subject'))
  end

  def test_new_unqualified_assignment_with_store_unqualified
    mock_store, mock_qualifier = Verdict::Storage::MockStorage.new, mock('qualifier')
    e = Verdict::Experiment.new('test') do
      qualify { mock_qualifier.qualifies? }
      storage mock_store, store_unqualified: true
    end

    mock_qualifier.expects(:qualifies?).returns(false)
    mock_store.expects(:retrieve_assignment).returns(nil).once
    mock_store.expects(:store_assignment).once
    e.assign(mock('subject'))
  end

  def test_returning_unqualified_assignment_with_store_unqualified
    mock_store, mock_qualifier = Verdict::Storage::MockStorage.new, mock('qualifier')
    e = Verdict::Experiment.new('test') do
      qualify { mock_qualifier.qualifies? }
      storage mock_store, store_unqualified: true
    end

    unqualified_assignment = e.subject_assignment(mock('subject_identifier'), nil, Time.now)
    mock_qualifier.expects(:qualifies?).never
    mock_store.expects(:retrieve_assignment).returns(unqualified_assignment).once
    mock_store.expects(:store_assignment).never
    e.assign(mock('subject'))
  end

  def test_assign_manually_stores_assignment
    mock_store = Verdict::Storage::MockStorage.new
    e = Verdict::Experiment.new('test') do
      storage mock_store, store_unqualified: true
      groups { group :all, 100 }
    end

    group = e.group('all')
    mock_store.expects(:store_assignment).once
    e.assign_manually(mock('subject'), group)
  end

  def test_disqualify_manually
    e = Verdict::Experiment.new('test', store_unqualified: true) do
      groups { group :all, 100 }
    end

    subject = stub(id: 'walrus')
    original_assignment = e.assign(subject)
    assert original_assignment.qualified?
    new_assignment = e.disqualify_manually(subject)
    refute new_assignment.qualified?
  end

  def test_disqualify_manually_fails_with_store_unqualified_disabled
    e = Verdict::Experiment.new('test', store_unqualified: false) do
      groups { group :all, 100 }
    end

    assert_raises(Verdict::Error) { e.disqualify_manually('subject') }
  end

  def test_returning_qualified_assignment_with_store_unqualified
    mock_store, mock_qualifier = Verdict::Storage::MockStorage.new, mock('qualifier')
    e = Verdict::Experiment.new('test') do
      qualify { mock_qualifier.qualifies? }
      storage mock_store, store_unqualified: true
      groups { group :all, 100 }
    end

    qualified_assignment = e.subject_assignment(mock('subject_identifier'), e.group(:all), Time.now)
    mock_qualifier.expects(:qualifies?).never
    mock_store.expects(:retrieve_assignment).returns(qualified_assignment).once
    mock_store.expects(:store_assignment).never
    e.assign(mock('subject'))
  end

  def test_dont_store_when_segmenter_returns_nil
    mock_store = Verdict::Storage::MockStorage.new
    e = Verdict::Experiment.new('test') do
      groups { group :all, 100 }
      storage mock_store, store_unqualified: true
    end

    e.segmenter.stubs(:assign).returns(nil)
    mock_store.expects(:store_assignment).never

    assignment = e.assign(mock('subject'))
    refute assignment.qualified?
  end

  def test_assignment_event_logging
    e = Verdict::Experiment.new('test') do
      groups { group :all, 100 }
    end

    e.stubs(:event_logger).returns(logger = mock('event_logger'))
    logger.expects(:log_assignment).with(kind_of(Verdict::Assignment))

    e.assign(stub(id: 'subject_identifier'))
  end

  def test_conversion_event_logging
    e = Verdict::Experiment.new('test')do
      groups { group :all, 100 }
    end

    subject = stub(id: 'test_subject')
    e.stubs(:event_logger).returns(logger = mock('logger'))
    logger.expects(:log_conversion).with(kind_of(Verdict::Conversion))
    e.segmenter.expects(:conversion_feedback).with('test_subject', subject, kind_of(Verdict::Conversion))

    conversion = e.convert(subject, :my_goal)
    assert_equal 'test_subject', conversion.subject_identifier
    assert_equal :my_goal, conversion.goal
  end

  def test_json
    e = Verdict::Experiment.new(:json) do
      name 'testing'
      subject_type 'visitor'
      groups do
        group :a, :half
        group :b, :rest
      end
    end

    Timecop.freeze(Time.new(2013, 2, 3, 4, 5, 6, '+00:00')) do
      e.send(:ensure_experiment_has_started)
    end

    json = JSON.parse(e.to_json)
    assert_equal 'json', json['handle']
    assert_equal false, json['has_qualifier']
    assert_kind_of Enumerable, json['groups']
    assert_equal 'testing', json['metadata']['name']
    assert_equal 'visitor', json['subject_type']
    assert_equal '2013-02-03T04:05:06Z', json['started_at']
  end

  def test_storage_read_failure
    storage_mock = Verdict::Storage::MockStorage.new
    e = Verdict::Experiment.new(:json) do
      groups { group :all, 100 }
      storage storage_mock
    end

    storage_mock.stubs(:retrieve_assignment).raises(Verdict::StorageError, 'storage read issues')
    rescued_assignment = e.assign(stub(id: 123))
    refute rescued_assignment.qualified?
  end

  def test_storage_write_failure
    storage_mock = Verdict::Storage::MockStorage.new
    e = Verdict::Experiment.new(:json) do
      groups { group :all, 100 }
      storage storage_mock
    end

    storage_mock.expects(:retrieve_assignment).returns(e.subject_assignment(mock('subject_identifier'), e.group(:all), nil))
    storage_mock.expects(:store_assignment).raises(Verdict::StorageError, 'storage write issues')
    rescued_assignment = e.assign(stub(id: 456))
    refute rescued_assignment.qualified?
  end

  def test_initial_started_at
    e = Verdict::Experiment.new('test') do
      groups { group :all, 100 }
    end

    e.storage.expects(:retrieve_start_timestamp).returns(nil)
    e.storage.expects(:store_start_timestamp).once
    e.send(:ensure_experiment_has_started)
  end

  def test_subsequent_started_at_when_start_time_is_memoized
    e = Verdict::Experiment.new('test') do
      groups { group :all, 100 }
    end

    e.send(:ensure_experiment_has_started)
    e.storage.expects(:retrieve_start_timestamp).never
    e.storage.expects(:store_start_timestamp).never
    e.send(:ensure_experiment_has_started)
  end

  def test_subsequent_started_at_when_start_time_is_not_memoized
    e = Verdict::Experiment.new('test') do
      groups { group :all, 100 }
    end

    e.storage.expects(:retrieve_start_timestamp).returns(Time.now.utc)
    e.storage.expects(:store_start_timestamp).never
    e.send(:ensure_experiment_has_started)
  end

  def test_qualify_based_on_experiment_start_timestamp
    Timecop.freeze(Time.new(2012)) do
      e = Verdict::Experiment.new('test') do
        qualify { |subject| subject.created_at >= self.started_at }
        groups { group :all, 100 }
      end

      subject = stub(id: 'old', created_at: Time.new(2011))
      refute e.assign(subject).qualified?

      subject = stub(id: 'new', created_at: Time.new(2013))
      assert e.assign(subject).qualified?
    end
  end

  def test_experiment_starting_behavior
    e = Verdict::Experiment.new('starting_test') do
      groups { group :all, 100 }
    end

    refute e.started?, "The experiment should not have started yet"

    e.assign(stub(id: '123'))
    assert e.started?, "The experiment should have started after the first assignment"
  end

  def test_experiment_set_start_timestamp_handles_storage_that_does_not_implement_timestamps
    e = Verdict::Experiment.new('starting_test') do
      groups { group :all, 100 }
    end

    e.storage.expects(:store_start_timestamp).raises(NotImplementedError)

    assert_nil e.send(:set_start_timestamp)
  end

  def test_no_storage
    e = Verdict::Experiment.new('starting_test') do
      groups { group :all, 100 }
      storage :none
    end

    assert_kind_of Verdict::Storage::MockStorage, e.storage
  end

  def test_cleanup
    storage = Verdict::Storage::RedisStorage.new(redis)
    experiment = Verdict::Experiment.new(:cleanup_test) do
      groups { group :all, 100 }
      storage storage, store_unqualified: true
    end

    experiment.assign("something")
    assert_operator redis, :exists, "experiments/cleanup_test"

    experiment.cleanup
    refute_operator redis, :exists, "experiments/cleanup_test"
  ensure
    redis.del("experiments/cleanup_test")
  end

  def test_cleanup_options
    experiment = Verdict::Experiment.new(:cleanup_test) do
      groups { group :all, 100 }
    end

    experiment.storage.expects(:clear).with(experiment.handle, some: :thing)
    experiment.assign("something")
    experiment.cleanup(some: :thing)
  end

  def test_cleanup_without_redis
    experiment = Verdict::Experiment.new(:cleanup_test) do
      groups { group :all, 100 }
    end

    assert_raises(NotImplementedError) do
      experiment.assign("something")
      experiment.cleanup
    end
  end

  def test_is_scheduled
    e = Verdict::Experiment.new(:json) do
      groups do
        group :a, :half
        group :b, :rest
      end
      schedule_start_timestamp Time.new(2020, 1, 1)
      schedule_end_timestamp Time.new(2020, 1, 3)
    end

    # Within the interval
    Timecop.freeze(Time.new(2020, 1, 2)) do
      assert e.send(:is_scheduled?)
    end
    # Too early
    Timecop.freeze(Time.new(2019, 12, 30)) do
      assert !e.send(:is_scheduled?)
    end
    # Too late
    Timecop.freeze(Time.new(2020, 1, 4)) do
      assert !e.send(:is_scheduled?)
    end
  end

  def test_is_scheduled_no_end_timestamp
    e = Verdict::Experiment.new(:json) do
      groups do
        group :a, :half
        group :b, :rest
      end
      schedule_start_timestamp Time.new(2020, 1, 1)
    end

    # Within the interval because there is no end date
    Timecop.freeze(Time.new(2030, 1, 1)) do
      assert e.send(:is_scheduled?)
    end
    # Too early
    Timecop.freeze(Time.new(2019, 12, 30)) do
      assert !e.send(:is_scheduled?)
    end
  end

  def test_is_scheduled_no_start_timestamp
    e = Verdict::Experiment.new(:json) do
      groups do
        group :a, :half
        group :b, :rest
      end
      schedule_end_timestamp Time.new(2020, 1, 3)
    end

    # Within the interval because there is no start date
    Timecop.freeze(Time.new(2019, 12, 30)) do
      assert e.send(:is_scheduled?)
    end
    # Too late
    Timecop.freeze(Time.new(2020, 1, 4)) do
      assert !e.send(:is_scheduled?)
    end
  end

  def test_switch_respects_time_schedule
    e = Verdict::Experiment.new('test') do
      groups do
        group :a, :half
        group :b, :rest
      end
      schedule_start_timestamp Time.new(2020, 1, 1)
      schedule_end_timestamp Time.new(2020, 1, 2)
    end

    Timecop.freeze(Time.new(2020, 1, 3)) do
      assert_nil e.switch(1)
    end
  end

  def test_switch_respects_time_schedule_even_after_assignment
    e = Verdict::Experiment.new('test') do
      groups do
        group :a, :half
        group :b, :rest
      end
    end

    assert_equal :a, e.switch(1)

    e.schedule_start_timestamp Time.new(2020, 1, 1)
    e.schedule_end_timestamp Time.new(2020, 1, 2)

    Timecop.freeze(Time.new(2020, 1, 3)) do
      assert_nil e.switch(1)
    end
  end

  def test_is_stop_new_assignments
    e = Verdict::Experiment.new('test') do
      groups do
        group :a, :half
        group :b, :half
      end
      schedule_stop_new_assignment_timestamp Time.new(2020, 1, 15)
    end

    # new assignments stopped after the stop timestamp
    Timecop.freeze(Time.new(2020, 1, 16)) do
      assert !e.send(:is_make_new_assignments?)
      assert_nil e.switch(1)
    end
    # new assignments didn't stop before the stop timestamp
    Timecop.freeze(Time.new(2020, 1, 3)) do
      assert e.send(:is_make_new_assignments?)
      assert :a, e.switch(2)
    end
  end

  def test_switch_preserves_old_assignments_after_stop_new_assignments_timestamp
    e = Verdict::Experiment.new('test') do
      groups do
        group :a, :half
        group :b, :half
      end
    end

    assert_equal :a, e.switch(1)

    e.schedule_stop_new_assignment_timestamp Time.new(2020, 4, 15)

    # switch respects to stop new assignment timestamp, old assignment preserves, new assignment returns nil
    Timecop.freeze(Time.new(2020, 4, 16)) do
      assert !e.send(:is_make_new_assignments?)
      # old assignment stay the same
      assert_equal :a, e.switch(1)
      # new assignment returns nil
      assert_nil e.switch(2)
    end
  end

  private

  def redis
    @redis ||= ::Redis.new(host: REDIS_HOST, port: REDIS_PORT)
  end
end

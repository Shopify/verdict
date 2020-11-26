require 'json'
require 'test_helper'

class ExperimentTest < Minitest::Test

  def test_no_qualifier
    e = Verdict::Experiment.new
    refute e.has_qualifier?
    assert e.everybody_qualifies?
  end

  def test_qualifier
    e = Class.new(Verdict::Experiment) do
      def self.name
        "Test"
      end

      qualify { |subject| subject.country == 'CA' }
      groups do
        group :all, 100
      end
    end.new

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
    e = Class.new(Verdict::Experiment) do
      def self.name
        "Test"
      end

      qualify { |subject| subject.language == 'fr' }
      qualify { |subject| subject.country == 'CA' }

      groups do
        group :all, 100
      end
    end.new

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
    e = Class.new(Verdict::Experiment) do
      def self.name
        "Test"
      end

      include CountryIsCanadaHelper

      qualify :country_is_canada

      groups do
        group :all, 100
      end
    end.new

    assert e.has_qualifier?
    refute e.everybody_qualifies?

    subject_stub = Struct.new(:id, :country)
    ca_subject = subject_stub.new(1, 'CA')
    us_subject = subject_stub.new(2, 'US')

    assert e.all_qualifiers_satisfied_for?(ca_subject, nil)
    refute e.all_qualifiers_satisfied_for?(us_subject, nil)

    qualified = e.assign(ca_subject)
    assert_kind_of Verdict::Assignment, qualified
    assert_equal e.group(:all), qualified.group

    non_qualified = e.assign(us_subject)
    assert_kind_of Verdict::Assignment, non_qualified
    refute non_qualified.qualified?
    assert_nil non_qualified.group
  end

  def test_disqualify_empty_identifier
    e = Class.new(Verdict::Experiment) do
      def self.name
        "Test"
      end

      self.disqualify_empty_identifier = true

      groups do
        group :a, :half
        group :b, :rest
      end
    end.new

    refute e.assign(nil).qualified?
    assert_nil e.convert('', :mygoal)
  end

  def test_assignment
    e = Class.new(Verdict::Experiment) do
      def self.name
        "Test"
      end

      qualify { |subject| subject <= 2 }

      groups do
        group :a, :half
        group :b, :rest
      end
    end.new

    assert_raises(Verdict::EmptySubjectIdentifier) { e.assign(nil) }

    assignment = e.assign(1)
    assert_kind_of Verdict::Assignment, assignment
    assert assignment.qualified?
    refute assignment.returning?
    assert_equal assignment.group, e.group(:a)

    assignment = e.assign(3)
    assert_kind_of Verdict::Assignment, assignment
    refute assignment.qualified?

    assert_equal :a, e.switch(1)
    assert_equal :b, e.switch(2)
    assert_nil e.switch(3)
  end

  def test_experiment_without_manual_assignment_timestamps_option
    e = Class.new(Verdict::Experiment) do
      def self.name
        "Test"
      end

      groups { group :all, 100 }
    end.new

    refute e.manual_assignment_timestamps?
  end

  def test_experiment_with_manual_assignment_timestamps_option
    e = Class.new(Verdict::Experiment) do
      def self.name
        "Test"
      end

      self.manual_assignment_timestamps = true

      groups { group :all, 100 }
    end.new

    assert e.manual_assignment_timestamps?
  end

  def test_subject_identifier
    e = Verdict::Experiment.new
    assert_equal '123', e.retrieve_subject_identifier(stub(id: 123, to_s: '456'))
    assert_equal '456', e.retrieve_subject_identifier(stub(to_s: '456'))
    assert_raises(Verdict::EmptySubjectIdentifier) { e.retrieve_subject_identifier(stub(id: nil)) }
    assert_raises(Verdict::EmptySubjectIdentifier) { e.retrieve_subject_identifier(stub(to_s: '')) }
  end

  def test_assignment_without_store_unqualified_always_fetches_old_assignment_if_available
    mock_store, mock_qualifier = Verdict::Storage::MockStorage.new, mock('qualifier')

    e = Class.new(Verdict::Experiment) do
      def self.name
        "Test"
      end

      qualify { mock_qualifier.qualifies? }
      storage mock_store, store_unqualified: false
      groups { group :all, 100 }
    end.new

    qualified_assignment = e.subject_assignment(mock('identifier'), e.group(:all), Time.now)

    mock_store.expects(:retrieve_assignment).returns(qualified_assignment).once
    mock_store.expects(:store_assignment).never

    e.assign(mock('subject'))
  end

  def test_new_unqualified_assignment_without_store_unqualified_does_not_store_if_merchant_not_qualified
    mock_store, mock_qualifier = Verdict::Storage::MockStorage.new, mock('qualifier')
    e = Class.new(Verdict::Experiment) do
      def self.name
        "Test"
      end

      qualify { mock_qualifier.qualifies? }
      storage mock_store, store_unqualified: false
      groups { group :all, 100 }
    end.new

    mock_qualifier.expects(:qualifies?).returns(false)
    mock_store.expects(:retrieve_assignment).returns(nil).once
    mock_store.expects(:store_assignment).never
    e.assign(mock('subject'))
  end

  def test_new_unqualified_assignment_with_store_unqualified
    mock_store, mock_qualifier = Verdict::Storage::MockStorage.new, mock('qualifier')
    e = Class.new(Verdict::Experiment) do
      def self.name
        "Test"
      end

      qualify { mock_qualifier.qualifies? }
      storage mock_store, store_unqualified: true
    end.new

    mock_qualifier.expects(:qualifies?).returns(false)
    mock_store.expects(:retrieve_assignment).returns(nil).once
    mock_store.expects(:store_assignment).once
    e.assign(mock('subject'))
  end

  def test_returning_unqualified_assignment_with_store_unqualified
    mock_store, mock_qualifier = Verdict::Storage::MockStorage.new, mock('qualifier')
    e = Class.new(Verdict::Experiment) do
      def self.name
        "Test"
      end

      qualify { mock_qualifier.qualifies? }
      storage mock_store, store_unqualified: true
    end.new

    unqualified_assignment = e.subject_assignment(mock('subject_identifier'), nil, Time.now)
    mock_qualifier.expects(:qualifies?).never
    mock_store.expects(:retrieve_assignment).returns(unqualified_assignment).once
    mock_store.expects(:store_assignment).never
    e.assign(mock('subject'))
  end

  def test_assign_manually_stores_assignment
    mock_store = Verdict::Storage::MockStorage.new
    e = Class.new(Verdict::Experiment) do
      def self.name
        "Test"
      end

      storage mock_store, store_unqualified: true
      groups { group :all, 100 }
    end.new

    group = e.group('all')
    mock_store.expects(:store_assignment).once
    e.assign_manually(mock('subject'), group)
  end

  def test_disqualify_manually
    e = Class.new(Verdict::Experiment) do
      def self.name
        "Test"
      end

      self.store_unqualified = true

      groups { group :all, 100 }
    end.new

    subject = stub(id: 'walrus')
    original_assignment = e.assign(subject)
    assert original_assignment.qualified?
    new_assignment = e.disqualify_manually(subject)
    refute new_assignment.qualified?
  end

  def test_disqualify_manually_fails_with_store_unqualified_disabled
    e = Class.new(Verdict::Experiment) do
      def self.name
        "Test"
      end

      self.store_unqualified = false

      groups { group :all, 100 }
    end.new

    assert_raises(Verdict::Error) { e.disqualify_manually('subject') }
  end

  def test_returning_qualified_assignment_with_store_unqualified
    mock_store, mock_qualifier = Verdict::Storage::MockStorage.new, mock('qualifier')
    e = Class.new(Verdict::Experiment) do
      def self.name
        "Test"
      end

      qualify { mock_qualifier.qualifies? }
      storage mock_store, store_unqualified: true
      groups { group :all, 100 }
    end.new

    qualified_assignment = e.subject_assignment(mock('subject_identifier'), e.group(:all), Time.now)
    mock_qualifier.expects(:qualifies?).never
    mock_store.expects(:retrieve_assignment).returns(qualified_assignment).once
    mock_store.expects(:store_assignment).never
    e.assign(mock('subject'))
  end

  def test_dont_store_when_segmenter_returns_nil
    mock_store = Verdict::Storage::MockStorage.new
    e = Class.new(Verdict::Experiment) do
      def self.name
        "Test"
      end

      groups { group :all, 100 }
      storage mock_store, store_unqualified: true
    end.new

    e.segmenter.stubs(:assign).returns(nil)
    mock_store.expects(:store_assignment).never

    assignment = e.assign(mock('subject'))
    refute assignment.qualified?
  end

  def test_assignment_event_logging
    e = Class.new(Verdict::Experiment) do
      def self.name
        "Test"
      end

      groups { group :all, 100 }
    end.new

    e.stubs(:event_logger).returns(logger = mock('event_logger'))
    logger.expects(:log_assignment).with(kind_of(Verdict::Assignment))

    e.assign(stub(id: 'subject_identifier'))
  end

  def test_conversion_event_logging
    e = Class.new(Verdict::Experiment) do
      def self.name
        "Test"
      end

      groups { group :all, 100 }
    end.new

    subject = stub(id: 'test_subject')
    e.stubs(:event_logger).returns(logger = mock('logger'))
    logger.expects(:log_conversion).with(kind_of(Verdict::Conversion))
    e.segmenter.expects(:conversion_feedback).with('test_subject', subject, kind_of(Verdict::Conversion))

    conversion = e.convert(subject, :my_goal)
    assert_equal 'test_subject', conversion.subject_identifier
    assert_equal :my_goal, conversion.goal
  end

  def test_json
    e = Class.new(Verdict::Experiment) do
      def self.name
        "Json"
      end

      self.subject_type = 'visitor'

      name_metadata 'testing'
      groups do
        group :a, :half
        group :b, :rest
      end
    end.new

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
    e = Class.new(Verdict::Experiment) do
      def self.name
        "Json"
      end

      groups { group :all, 100 }
      storage storage_mock
    end.new

    storage_mock.stubs(:retrieve_assignment).raises(Verdict::StorageError, 'storage read issues')
    rescued_assignment = e.assign(stub(id: 123))
    refute rescued_assignment.qualified?
  end

  def test_storage_write_failure
    storage_mock = Verdict::Storage::MockStorage.new
    e = Class.new(Verdict::Experiment) do
      def self.name
        "Json"
      end

      groups { group :all, 100 }
      storage storage_mock
    end.new

    storage_mock.expects(:retrieve_assignment).returns(e.subject_assignment(mock('subject_identifier'), e.group(:all), nil))
    storage_mock.expects(:store_assignment).raises(Verdict::StorageError, 'storage write issues')
    rescued_assignment = e.assign(stub(id: 456))
    refute rescued_assignment.qualified?
  end

  def test_initial_started_at
    e = Class.new(Verdict::Experiment) do
      def self.name
        "Test"
      end

      groups { group :all, 100 }
    end.new

    e.storage.expects(:retrieve_start_timestamp).returns(nil)
    e.storage.expects(:store_start_timestamp).once
    e.send(:ensure_experiment_has_started)
  end

  def test_subsequent_started_at_when_start_time_is_memoized
    e = Class.new(Verdict::Experiment) do
      def self.name
        "Test"
      end

      groups { group :all, 100 }
    end.new

    e.send(:ensure_experiment_has_started)
    e.storage.expects(:retrieve_start_timestamp).never
    e.storage.expects(:store_start_timestamp).never
    e.send(:ensure_experiment_has_started)
  end

  def test_subsequent_started_at_when_start_time_is_not_memoized
    e = Class.new(Verdict::Experiment) do
      def self.name
        "Test"
      end

      groups { group :all, 100 }
    end.new

    e.storage.expects(:retrieve_start_timestamp).returns(Time.now.utc)
    e.storage.expects(:store_start_timestamp).never
    e.send(:ensure_experiment_has_started)
  end

  def test_qualify_based_on_experiment_start_timestamp
    Timecop.freeze(Time.new(2012)) do
      e = Class.new(Verdict::Experiment) do
        def self.name
          "Test"
        end

        qualify { |subject| subject.created_at >= self.started_at }
        groups { group :all, 100 }
      end.new

      subject = stub(id: 'old', created_at: Time.new(2011))
      refute e.assign(subject).qualified?

      subject = stub(id: 'new', created_at: Time.new(2013))
      assert e.assign(subject).qualified?
    end
  end

  def test_experiment_starting_behavior
    e = Class.new(Verdict::Experiment) do
      def self.name
        "StartingTest"
      end

      groups { group :all, 100 }
    end.new

    refute e.started?, "The experiment should not have started yet"

    e.assign(stub(id: '123'))
    assert e.started?, "The experiment should have started after the first assignment"
  end

  def test_experiment_set_start_timestamp_handles_storage_that_does_not_implement_timestamps
    e = Class.new(Verdict::Experiment) do
      def self.name
        "StartingTest"
      end

      groups { group :all, 100 }
    end.new

    e.storage.expects(:store_start_timestamp).raises(NotImplementedError)

    assert_nil e.send(:set_start_timestamp)
  end

  def test_no_storage
    e = Class.new(Verdict::Experiment) do
      def self.name
        "StartingTest"
      end

      groups { group :all, 100 }
      storage :none
    end.new

    assert_kind_of Verdict::Storage::MockStorage, e.storage
  end

  def test_cleanup
    storage = Verdict::Storage::RedisStorage.new(redis)
    experiment = Class.new(Verdict::Experiment) do
      def self.name
        "CleanupTest"
      end

      groups { group :all, 100 }
      storage storage, store_unqualified: true
    end.new

    experiment.assign("something")
    assert_operator redis, :exists, "experiments/cleanup_test"

    experiment.cleanup
    refute_operator redis, :exists, "experiments/cleanup_test"
  ensure
    redis.del("experiments/cleanup_test")
  end

  def test_cleanup_options
    experiment = Class.new(Verdict::Experiment) do
      def self.name
        "CleanupTest"
      end

      groups { group :all, 100 }
    end.new

    experiment.storage.expects(:clear).with(experiment.handle, some: :thing)
    experiment.assign("something")
    experiment.cleanup(some: :thing)
  end

  def test_cleanup_without_redis
    experiment = Class.new(Verdict::Experiment) do
      def self.name
        "CleanupTest"
      end

      groups { group :all, 100 }
    end.new

    assert_raises(NotImplementedError) do
      experiment.assign("something")
      experiment.cleanup
    end
  end

  def test_is_scheduled
    e = Class.new(Verdict::Experiment) do
      def self.name
        "Json"
      end

      groups do
        group :a, :half
        group :b, :rest
      end
      self.schedule_start_timestamp = Time.new(2020, 1, 1)
      self.schedule_end_timestamp = Time.new(2020, 1, 3)
    end.new

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
    e = Class.new(Verdict::Experiment) do
      def self.name
        "Json"
      end

      groups do
        group :a, :half
        group :b, :rest
      end
      self.schedule_start_timestamp = Time.new(2020, 1, 1)
    end.new

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
    e = Class.new(Verdict::Experiment) do
      def self.name
        "Json"
      end

      groups do
        group :a, :half
        group :b, :rest
      end
      self.schedule_end_timestamp = Time.new(2020, 1, 3)
    end.new

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
    e = Class.new(Verdict::Experiment) do
      def self.name
        "Test"
      end

      groups do
        group :a, :half
        group :b, :rest
      end

      self.schedule_start_timestamp = Time.new(2020, 1, 1)
      self.schedule_end_timestamp = Time.new(2020, 1, 2)
    end.new

    Timecop.freeze(Time.new(2020, 1, 3)) do
      assert_nil e.switch(1)
    end
  end

  def test_switch_respects_time_schedule_even_after_assignment
    e = Class.new(Verdict::Experiment) do
      def self.name
        "Test"
      end

      groups do
        group :a, :half
        group :b, :rest
      end
    end.new

    assert_equal :a, e.switch(1)

    e.schedule_start_timestamp = Time.new(2020, 1, 1)
    e.schedule_end_timestamp = Time.new(2020, 1, 2)

    Timecop.freeze(Time.new(2020, 1, 3)) do
      assert_nil e.switch(1)
    end
  end

  def test_is_stop_new_assignments
    e = Class.new(Verdict::Experiment) do
      def self.name
        "Test"
      end

      groups do
        group :a, :half
        group :b, :half
      end
      self.schedule_stop_new_assignment_timestamp = Time.new(2020, 1, 15)
    end.new

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
    e = Class.new(Verdict::Experiment) do
      def self.name
        "Test"
      end

      groups do
        group :a, :half
        group :b, :half
      end
    end.new

    assert_equal :a, e.switch(1)

    e.schedule_stop_new_assignment_timestamp = Time.new(2020, 4, 15)

    # switch respects to stop new assignment timestamp, old assignment preserves, new assignment returns nil
    Timecop.freeze(Time.new(2020, 4, 16)) do
      assert !e.send(:is_make_new_assignments?)
      # old assignment stay the same
      assert_equal :a, e.switch(1)
      # new assignment returns nil
      assert_nil e.switch(2)
    end
  end

  def test_schedule_start_timestamp_and_stop_new_assignemnt_timestamp_are_inclusive_but_end_timestamp_is_exclusive
    e = Class.new(Verdict::Experiment) do
      def self.name
        "Test"
      end

      groups do
        group :a, :half
        group :b, :half
      end

      self.schedule_start_timestamp = Time.new(2020, 1, 1)
      self.schedule_stop_new_assignment_timestamp = Time.new(2020, 1, 15)
      self.schedule_end_timestamp = Time.new(2020, 1, 31)
    end.new

    # start_timestamp is included
    Timecop.freeze(Time.new(2020, 1, 1)) do
      assert e.send(:is_scheduled?)
      assert_equal :a, e.switch(1)
    end

    # stop_new_assignment_timestamp is included
    Timecop.freeze(Time.new(2020, 1, 15)) do
      assert !e.send(:is_make_new_assignments?)
      # old assignment preserved
      assert_equal :a, e.switch(1)
      # new assignment returns nil
      assert_nil e.switch(2)
    end

    # end_timestamp is excluded
    Timecop.freeze(Time.new(2020, 1, 31)) do
      assert !e.send(:is_scheduled?)
      assert_nil e.switch(1)
    end
  end

  def test_custom_qualifiers_success
    e = Class.new(Verdict::Experiment) do
      def self.name
        "Test"
      end

      groups do
        group :all, 100
      end
    end.new

    subject = 2
    custom_qualifier_a = Proc.new { |subject| subject.even? }
    custom_qualifier_b = Proc.new { |subject| subject > 0 }

    group = e.switch(subject, qualifiers: [custom_qualifier_a, custom_qualifier_b])
    assert_equal e.group(:all).to_sym, group
  end

  def test_custom_qualifiers_failure
    e = Class.new(Verdict::Experiment) do
      def self.name
        "Test"
      end

      groups do
        group :all, 100
      end
    end.new

    subject = 3
    custom_qualifier_a = Proc.new { |subject| subject.even? }
    custom_qualifier_b = Proc.new { |subject| subject > 0 }

    group = e.switch(subject, qualifiers: [custom_qualifier_a, custom_qualifier_b])
    assert_nil group
  end

  def test_dynamic_subject_qualifies_call_overridden_method
    e = Class.new(MyExperiment) do
      def self.name
        "Test"
      end

      groups do
        group :all, 100
      end
    end.new

    group = e.switch(4)
    assert_nil group
  end

  private

  def redis
    @redis ||= ::Redis.new(host: REDIS_HOST, port: REDIS_PORT)
  end
end

class MyExperiment < Verdict::Experiment
  def subject_qualifies?(subject, context = nil)
    return false if subject.even?
    super
  end
end

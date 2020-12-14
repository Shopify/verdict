# frozen_string_literal: true

require 'test_helper'
require 'fake_app'

class CookieStorageTest < Minitest::Test
  def setup
    @storage = Verdict::Storage::CookieStorage.new.tap do |s|
      request = mock()
      request.stubs(:cookies_same_site_protection).returns(proc { :none })
      s.cookies = ActionDispatch::Cookies::CookieJar.new(request)
    end
    @experiment = Verdict::Experiment.new(:cookie_storage_test) do
      groups { group :all, 100 }
      storage @storage, store_unqualified: true
    end
    @subject = stub(id: 'bob')
    @assignment = Verdict::Assignment.new(@experiment, @subject, @experiment.group(:all), nil)
  end

  def test_cookie_lifespan_has_a_default
    cookie_lifespan = Verdict::Storage::CookieStorage.new.cookie_lifespan

    assert_equal Verdict::Storage::CookieStorage::DEFAULT_COOKIE_LIFESPAN_SECONDS, cookie_lifespan
  end

  def test_cookie_lifespan_can_be_configured
    storage = Verdict::Storage::CookieStorage.new(cookie_lifespan: 60)

    assert_equal 60, storage.cookie_lifespan
  end

  def test_raises_storage_error_when_cookies_is_nil
    storage = Verdict::Storage::CookieStorage.new

    assert_raises(Verdict::StorageError) { storage.store_assignment(@assignment) }
    assert_raises(Verdict::StorageError) { storage.retrieve_assignment(@experiment, @subject) }
    assert_raises(Verdict::StorageError) { storage.remove_assignment(@experiment, @subject) }
  end

  def test_store_assignment_returns_true_when_an_assignment_is_stored
    assert @storage.store_assignment(@assignment)
    refute_nil @storage.retrieve_assignment(@experiment, @subject)
  end

  def test_retrieve_assignment_returns_an_assignment
    @storage.store_assignment(@assignment)
    assignment = @storage.retrieve_assignment(@experiment, @subject)

    assert assignment.returning?
    assert_equal :all, assignment.handle.to_sym
    assert_equal @experiment, assignment.experiment
    assert_equal @subject, assignment.subject
  end

  def test_retrieve_assignment_returns_nil_when_an_assignment_does_not_exist
    assert_nil @storage.retrieve_assignment(@experiment, @subject)
  end

  def test_retrieve_assignment_returns_nil_when_the_assignment_group_is_invalid
    invalid_group = Verdict::Group.new(@experiment, :invalid)
    assignment = Verdict::Assignment.new(@experiment, @subject, invalid_group, nil)

    @storage.store_assignment(assignment)

    assert_nil @storage.retrieve_assignment(@experiment, @subject)
  end

  def test_remove_assignment_returns_true_when_removing_an_assignment
    @storage.store_assignment(@assignment)

    assert @storage.remove_assignment(@experiment, nil)
    assert_nil @storage.retrieve_assignment(@experiment, @subject)
  end

  def test_retrieve_start_timestamp_always_returns_nil
    assert_nil @storage.retrieve_start_timestamp(nil)
  end

  def test_store_start_timestamp_raises_not_implemented_error
    assert_raises(NotImplementedError) { @storage.store_start_timestamp(nil, nil) }
  end
end

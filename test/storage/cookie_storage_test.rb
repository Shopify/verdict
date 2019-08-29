# frozen_string_literal: true

require 'test_helper'

class CookieStorageTest < Minitest::Test
  def setup
    @storage = storage = Verdict::Storage::CookieStorage.new
    @experiment = Verdict::Experiment.new(:cookie_storage_test) do
      name 1234
      groups do
        group :all, 100 do name 5678
        end
      end
      storage storage, store_unqualified: true
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

  def test_store_assignment_returns_true_when_an_assignment_is_stored
    assert @storage.store_assignment(@assignment)
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
    invalid_group.name('invalid')
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

  def test_store_start_timestamp_always_returns_true
    assert @storage.store_start_timestamp(nil, nil)
  end
end

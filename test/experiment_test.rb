require 'test_helper'

class ExperimentTest < MiniTest::Unit::TestCase

  def test_qualifier
    e = Experiments.define('test') do |experiment|
      qualify { |subject| subject.country == 'CA' }
      groups do
        group :all, 100
      end
    end

    subject_stub = Struct.new(:id, :country)
    ca_subject = subject_stub.new(1, 'CA')
    us_subject = subject_stub.new(1, 'US')

    assert e.qualifier.call(ca_subject)
    assert !e.qualifier.call(us_subject)

    qualified = e.assign(ca_subject)
    assert_kind_of Experiments::Assignment, qualified
    assert_equal e.group(:all), qualified.group

    non_qualified = e.assign(us_subject)
    assert_kind_of Experiments::Assignment, non_qualified
    assert !non_qualified.qualified?
    assert_equal nil, non_qualified.group
  end

  def test_assignment
    e = Experiments::Experiment.new('test') do
      qualify { |subject| subject <= 2 }
      groups do
        group :a, :half
        group :b, :rest
      end
    end

    assignment = e.assign(1)
    assert_kind_of Experiments::Assignment, assignment
    assert assignment.qualified?
    assert !assignment.returning?
    assert_equal assignment.group, e.group(:a)

    assignment = e.assign(3)
    assert_kind_of Experiments::Assignment, assignment
    assert !assignment.qualified?
  end

  def test_logging
    Experiments.logger = MiniTest::Mock.new
    e = Experiments::Experiment.new('test') do
      qualify { |subject| subject <= 2 }
      groups do
        group :a, :half
        group :b, :rest
      end
    end

    Experiments.logger.expect(:info, nil, ['[Experiments] experiment=test subject=1 status=new qualified=true group=a'])
    e.assign(1)
    Experiments.logger.verify

    Experiments.logger.expect(:info, nil, ['[Experiments] experiment=test subject=2 status=new qualified=true group=b'])
    e.assign(2)
    Experiments.logger.verify

    Experiments.logger.expect(:info, nil, ['[Experiments] experiment=test subject=3 status=new qualified=false'])
    e.assign(3)
    Experiments.logger.verify
  end

  def test_with_memory_store
    Experiments.logger = MiniTest::Mock.new
    e = Experiments::Experiment.new('test') do
      groups do
        group :a, :half
        group :b, :rest
      end

      storage(Experiments::Storage::Memory.new)
    end

    Experiments.logger.expect(:info, nil, ['[Experiments] experiment=test subject=1 status=new qualified=true group=a'])
    assignment = e.assign(1)
    assert !assignment.returning?
    Experiments.logger.verify

    Experiments.logger.expect(:info, nil, ['[Experiments] experiment=test subject=1 status=returning qualified=true group=a'])
    assignment = e.assign(1)
    assert assignment.returning?
    Experiments.logger.verify
  end
end

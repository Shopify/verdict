require 'test_helper'

class ExperimentTest < MiniTest::Unit::TestCase

  def setup
    Experiments.repository.clear
  end

  def test_should_keep_list_of_all
    size_at_start = Experiments.repository.size
    e = Experiments::Experiment.new('test')

    assert_equal size_at_start + 1, Experiments.repository.size
    assert_equal e, Experiments['test']
  end

  def test_should_not_allow_experiments_with_the_same_name
    Experiments::Experiment.new('test_duplicate')
    assert_raises(Experiments::ExperimentNameNotUnique) do
      Experiments::Experiment.new('test_duplicate')
    end
  end

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

    assert_equal :all, e.assign(ca_subject)
    assert_nil e.assign(us_subject)
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
    e.assign(1)
    Experiments.logger.verify

    Experiments.logger.expect(:info, nil, ['[Experiments] experiment=test subject=1 status=returning qualified=true group=a'])
    e.assign(1)
    Experiments.logger.verify
  end
end

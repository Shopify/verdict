require 'test_helper'

class ExperimentTest < MiniTest::Unit::TestCase

  def test_no_qualifier
    e = Experiments.define('test')
    assert !e.has_qualifier?
    assert e.everybody_qualifies?
  end

  def test_qualifier
    e = Experiments.define('test') do |experiment|
      qualify { |subject| subject.country == 'CA' }
      groups do
        group :all, 100
      end
    end

    assert e.has_qualifier?
    assert !e.everybody_qualifies?

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

    assert_equal :a,  e.switch(1)
    assert_equal :b,  e.switch(2)
    assert_equal nil, e.switch(3)
  end

  def test_logging
    e = Experiments::Experiment.new('test') do
      qualify { |subject| subject <= 2 }
      groups do
        group :a, :half
        group :b, :rest
      end
    end

    Experiments.stubs(:logger).returns(logger = mock('logger'))

    logger.expects(:info).with('[Experiments] experiment=test subject=1 status=new qualified=true group=a')
    e.assign(1)  

    logger.expects(:info).with('[Experiments] experiment=test subject=2 status=new qualified=true group=b')
    e.assign(2)

    logger.expects(:info).with('[Experiments] experiment=test subject=3 status=new qualified=false')
    e.assign(3)
  end

  def test_with_memory_store
    e = Experiments::Experiment.new('test') do
      groups do
        group :a, :half
        group :b, :rest
      end

      storage(Experiments::Storage::Memory.new)
    end

    Experiments.stubs(:logger).returns(logger = mock('logger'))
    
    logger.expects(:info).with('[Experiments] experiment=test subject=1 status=new qualified=true group=a')
    assignment = e.assign(1)
    assert !assignment.returning?
    
    logger.expects(:info).with('[Experiments] experiment=test subject=1 status=returning qualified=true group=a')
    assignment = e.assign(1)
    assert assignment.returning?
  end

  def test_json
    e = Experiments::Experiment.new(:json) do
      name 'testing'
      groups do
        group :a, :half
        group :b, :rest
      end
    end

    json = JSON.parse(e.to_json)
    assert_equal 'json', json['handle']
    assert_equal false, json['has_qualifier']
    assert_kind_of Enumerable, json['groups']
    assert_equal 'testing', json['metadata']['name']
  end
end

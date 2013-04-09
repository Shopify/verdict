require 'test_helper'

class ExperimentTest < MiniTest::Unit::TestCase

  def test_logging
    Experiments.logger = MiniTest::Mock.new
    qualifier = proc { |subject| subject == 1 }
    e = Experiments::Experiment.new('test', qualifier: qualifier) do |segment|
      segment.half :a
      segment.rest :b
    end

    Experiments.logger.expect(:info, nil, ['[Experiment test] subject ID "1" is in segment :a.'])
    Experiments.logger.expect(:info, nil, ['[Experiment test] subject ID "2" is not qualified.'])

    e.segment_for(1)
    e.segment_for(2)

    Experiments.logger.verify
  end

  def test_qualifier
    subject_stub = Struct.new(:id, :country)
    qualifier = proc { |subject| subject.country == 'CA' }
    e = Experiments::Experiment.new('test', qualifier: qualifier) { |s| s.percentage(100, :all) }

    ca_subject = subject_stub.new(1, 'CA')
    us_subject = subject_stub.new(1, 'US')

    assert e.qualifier.call(ca_subject)
    assert !e.qualifier.call(us_subject)

    assert_equal :all, e.segment_for(ca_subject)
    assert_nil e.segment_for(us_subject)
  end
end

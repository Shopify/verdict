require 'test_helper'

class StaticSegmenterTest < Minitest::Test

  def setup
    @segmenter = Verdict::StaticSegmenter.new(Verdict::Experiment.new('test'))
    @segmenter.group :beta, ['id1', 'id2']
  end

  def test_group_definition
    assert_equal ['beta'], @segmenter.groups.keys
    assert_equal ['id1', 'id2'], @segmenter.groups['beta'].subject_identifiers
  end

  def test_group_json_representation
    json = JSON.parse(@segmenter.groups['beta'].to_json)
    assert_equal 'beta', json['handle']
    assert_equal ['id1', 'id2'], json['subject_identifiers']
  end

  def test_assigment
    assert_equal @segmenter.groups['beta'], @segmenter.assign('id2', stub(id: 'id2'), nil)
    assert_equal nil, @segmenter.assign('id3', stub(id: 'id3'), nil)
  end
end

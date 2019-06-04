require 'test_helper'
require 'stringio'

class RakeTasksTest < Minitest::Test

  TestSubjectClass = Struct.new(:id)
  class TestExperiment < Verdict::Experiment
    def fetch_subject(subject_identifier)
      TestSubjectClass.new(subject_identifier.to_i)
    end
  end

  def setup
    require 'rake' unless defined?(Rake)
    Rake::Task.define_task(:environment)
    Rake.application.rake_require('verdict/tasks')

    @experiment = TestExperiment.define(:rake, store_unqualified: true) do
      groups do
        group :a, 50
        group :b, 50
      end
    end

    ENV['EXPERIMENT'] = 'rake'
    ENV['SUBJECT']    = '1'
    ENV['GROUP']      = 'a'

    Verdict::Rake.stubs(:stdout).returns(@stdout = StringIO.new)
  end

  def teardown
    Rake::Task["environment"].reenable
    Rake::Task["verdict:lookup_assignment"].reenable
    Rake::Task["verdict:experiments"].reenable
    Rake::Task["verdict:assign_manually"].reenable
    Rake::Task["verdict:disqualify_manually"].reenable
    Rake::Task["verdict:remove_assignment"].reenable

    Verdict.repository.clear
  end

  def test_require_env
    assert_equal 'a', Verdict::Rake.require_env('GROUP')
    assert_equal 'a', Verdict::Rake.require_env('group')

    ENV['group'] = 'b'
    assert_equal 'a', Verdict::Rake.require_env('group') # uppercase has presedence

    assert_raises(ArgumentError) { Verdict::Rake.require_env('non_existent_env') }
  end

  def test_experiment_list
    Rake.application.invoke_task("verdict:experiments")
    assert_equal 'rake | Groups: a (50%), b (50%)', @stdout.string.chomp
  end

  def test_lookup_assignment_fails_without_experiment_env_variable
    ENV['EXPERIMENT'] = ''
    assert_raises(ArgumentError) { Rake.application.invoke_task("verdict:lookup_assignment") }
  end

  def test_lookup_assignment_fails_without_subject_env_variable
    ENV.delete('SUBJECT')
    assert_raises(ArgumentError) { Rake.application.invoke_task("verdict:lookup_assignment") }
  end

  def test_assign_manually
    Rake.application.invoke_task("verdict:assign_manually")
    assert_equal 'Subject `1` has been assigned to group `a` of experiment `rake`.', @stdout.string.chomp

    @stdout.string = ""
    Rake.application.invoke_task("verdict:lookup_assignment")
    assert_equal 'Subject `1` is assigned to group `a` of experiment `rake`.', @stdout.string.chomp
  end

  def test_disqualify_manually
    Rake.application.invoke_task("verdict:disqualify_manually")
    assert_equal 'Subject `1` has been disqualified from experiment `rake`.', @stdout.string.chomp

    @stdout.string = ""
    Rake.application.invoke_task("verdict:lookup_assignment")
    assert_equal 'Subject `1` is unqualified for experiment `rake`.', @stdout.string.chomp
  end

  def test_remove_assignment
    @experiment.assign('1')
    Rake.application.invoke_task("verdict:remove_assignment")
    assert_equal 'Removed assignment of subject with identifier `1`.', @stdout.string.lines.to_a[0].chomp
    assert_equal 'The subject will be reasigned when it encounters the experiment `rake` again.', @stdout.string.lines.to_a[1].chomp

    @stdout.string = ""
    Rake.application.invoke_task("verdict:lookup_assignment")
    assert_equal 'Subject `1` is not assigned to experiment `rake` yet.', @stdout.string.chomp
  end
end

module Verdict
  module Rake
    def self.require_env(key)
      if ENV.has_key?(key.upcase) && !ENV[key.upcase].empty?
        ENV[key.upcase]
      elsif ENV.has_key?(key.downcase) && !ENV[key.downcase].empty?
        ENV[key.downcase]
      else
        raise ArgumentError, "Provide #{key.upcase} as environment variable"
      end
    end

    def self.stdout
      $stdout
    end

    def self.experiment
      experiment_handle = Verdict::Rake.require_env('experiment')
      Verdict[experiment_handle] or raise "Experiment `#{experiment_handle}` not found"
    end

    def self.group
      group_handle = Verdict::Rake.require_env('group')
      experiment.group(group_handle) or raise "Group `#{group_handle}` not found."
    end

    def self.subject_identifier
      Verdict::Rake.require_env('subject')
    end

    def self.subject
      experiment.fetch_subject(subject_identifier)
    end
  end
end

namespace :verdict do

  desc "List all defined experiments"
  task :experiments => 'environment' do
    length = Verdict.repository.keys.map(&:length).max
    Verdict.repository.each do |_, experiment|
      Verdict::Rake.stdout.print "#{experiment.handle.ljust(length)} | "
      Verdict::Rake.stdout.print "Groups: #{experiment.groups.values.map(&:to_s).join(', ')}"
      Verdict::Rake.stdout.puts
    end
  end

  desc "Looks up the assignment for a given experiment and subject"
  task :lookup_assignment => 'environment' do
    experiment         = Verdict::Rake.experiment
    subject_identifier = Verdict::Rake.subject_identifier
    subject            = Verdict::Rake.subject

    assignment = experiment.lookup(subject)
    if assignment.nil?
      Verdict::Rake.stdout.puts "Subject `#{subject_identifier}` is not assigned to experiment `#{experiment.handle}` yet."
    elsif assignment.qualified?
      Verdict::Rake.stdout.puts "Subject `#{subject_identifier}` is assigned to group `#{assignment.group.handle}` of experiment `#{experiment.handle}`."
    else
      Verdict::Rake.stdout.puts "Subject `#{subject_identifier}` is unqualified for experiment `#{experiment.handle}`."
    end
  end

  desc "Manually assign a subject to a given group in an experiment"
  task :assign_manually => 'environment' do
    experiment         = Verdict::Rake.experiment
    group              = Verdict::Rake.group
    subject_identifier = Verdict::Rake.subject_identifier
    subject            = Verdict::Rake.subject

    experiment.assign_manually(subject, group)
    Verdict::Rake.stdout.puts "Subject `#{subject_identifier}` has been assigned to group `#{group.handle}` of experiment `#{experiment.handle}`."
  end

  desc "Manually disqualify a subject from an experiment"
  task :disqualify_manually => 'environment' do
    experiment         = Verdict::Rake.experiment
    subject_identifier = Verdict::Rake.subject_identifier
    subject            = Verdict::Rake.subject

    experiment.disqualify_manually(subject)
    Verdict::Rake.stdout.puts "Subject `#{subject_identifier}` has been disqualified from experiment `#{experiment.handle}`."
  end

  desc "Removes the assignment for a subject so it will be reassigned to the experiment."
  task :remove_assignment => 'environment' do
    experiment         = Verdict::Rake.experiment
    subject_identifier = Verdict::Rake.subject_identifier
    subject            = Verdict::Rake.subject

    experiment.remove_subject_assignment(subject)
    Verdict::Rake.stdout.puts "Removed assignment of subject with identifier `#{subject_identifier}`."
    Verdict::Rake.stdout.puts "The subject will be reasigned when it encounters the experiment `#{experiment.handle}` again."
  end
end

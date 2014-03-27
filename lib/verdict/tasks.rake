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
    experiment = Verdict[Verdict::Rake.require_env('experiment')] or raise "Experiment not found"
    subject_identifier = Verdict::Rake.require_env('subject')
    assignment = experiment.lookup_assignment_for_identifier(subject_identifier)
    if assignment.nil?
      Verdict::Rake.stdout.puts "Subject #{subject_identifier} is not assigned to experiment `#{experiment.handle}` yet."
    elsif assignment.qualified?
      Verdict::Rake.stdout.puts "Subject #{subject_identifier} is assigned to group `#{assignment.group.handle}` of experiment `#{experiment.handle}`."
    else
      Verdict::Rake.stdout.puts "Subject #{subject_identifier} is unqualified for experiment `#{experiment.handle}`."
    end
  end

  desc "Manually assign a subject to a given group in an experiment"
  task :assign_manually => 'environment' do
    experiment = Verdict[Verdict::Rake.require_env('experiment')] or raise "Experiment not found."
    group = experiment.group(Verdict::Rake.require_env('group')) or raise "Group not found."
    experiment.assign_manually_by_identifier(Verdict::Rake.require_env('subject'), group)
  end

  desc "Manually disqualify a subject from an experiment"
  task :disqualify_manually => 'environment' do
    experiment = Verdict[Verdict::Rake.require_env('experiment')] or raise "Experiment not found."
    experiment.disqualify_manually_by_identifier(Verdict::Rake.require_env('subject'))
  end

  desc "Removes the assignment for a subject so it will be reassigned to the experiment."
  task :remove_assignment => 'environment' do
    experiment = Verdict[Verdict::Rake.require_env('experiment')] or raise "Experiment not found."
    experiment.remove_subject_assignment_by_identifier(Verdict::Rake.require_env('subject'))
  end
end

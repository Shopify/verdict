def require_env(key)
  value = ENV[key.downcase].presence || ENV[key.upcase].presence
  raise "Provide #{key} as environment variable" if value.blank?
  value
end

namespace :experiments do

  desc "List all defined experiments"
  task :list => 'environment' do
    length = Verdict.repository.keys.map(&:length).max
    Verdict.repository.each do |_, experiment|
      print "#{experiment.handle.ljust(length)} | "
      print "Groups: #{experiment.groups.values.map(&:to_s).join(', ')}"
      puts
    end
  end

  desc "Looks up the assignment for a given experiment and subject"
  task :lookup_assignment => 'environment' do
    experiment = Verdict[require_env('experiment')] or raise "Experiment not found"
    subject_identifier = require_env('subject')
    assignment = experiment.lookup_assignment_for_identifier(subject_identifier)
    if assignment.nil?
      puts "Subject #{ENV['subject']} is not assigned to experiment #{experiment.handle} yet."
    elsif assignment.qualified?
      puts "Subject #{ENV['subject']} is assigned to group `#{assignment.group.handle}`"
    else
      puts "Subject #{ENV['subject']} is unqualified for experiment #{experiment.handle}"
    end
  end

  desc "Manually assign a subject to a given group in an experiment"
  task :assign_manually => 'environment' do
    experiment = Verdict[require_env('experiment')] or raise "Experiment not found"
    group = experiment.group(require_env('group')) or raise "Group not found"
    assignment = experiment.subject_assignment(require_env('subject'), group, false)
    experiment.store_assignment(assignment)
  end

  desc "Disqualify a subject from an experiment"
  task :disqualify => 'environment' do
    experiment = Verdict[require_env('experiment')] or raise "Experiment not found"
    assignment = experiment.subject_assignment(require_env('subject'), nil, false)
    experiment.store_assignment(assignment)
  end

  desc "Removes the assignment for a subject so it will be reassigned to the experiment."
  task :remove_assignment => 'environment' do
    experiment = Verdict[require_env('experiment')] or raise "Experiment not found"
    experiment.remove_subject_identifier(require_env('subject'))
  end

  desc "Runs the cleanup tasks for an experiment"
  task :wrapup => 'environment' do
    experiment = Verdict[require_env('experiment')] or raise "Experiment not found"
    experiment.wrapup
  end
end

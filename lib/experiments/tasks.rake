def require_env(key)
  value = ENV[key.downcase].presence || ENV[key.upcase].presence
  raise "Provide #{key} as environment variable" if value.blank?
  value
end

namespace :experiments do
  
  desc "List all defined experiments"
  task :list => 'environment' do
    length = Experiments.repository.keys.map(&:length).max
    Experiments.repository.each do |_, experiment|
      print "#{experiment.handle.ljust(length)} | "
      print "Groups: #{experiment.groups.values.map(&:to_s).join(', ')}"
      puts
    end
  end

  task :lookup_assignment => 'environment' do
    experiment = Experiments[require_env('experiment')] or raise "Experiment not found"
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

  task :wrapup => 'environment' do
    experiment = Experiments[require_env('experiment')] or raise "Experiment not found"
    experiment.wrapup
  end

  task :assign_manually => 'environment' do
    experiment = Experiments[require_env('experiment')] or raise "Experiment not found"
    group = experiment.group(require_env('group')) or raise "Group not found"
    assignment = experiment.subject_assignment(require_env('subject'), group, false)
    experiment.store_assignment(assignment)
  end

  task :disqualify => 'environment' do
    experiment = Experiments[require_env('experiment')] or raise "Experiment not found"
    assignment = experiment.subject_assignment(require_env('subject'), nil, false)
    experiment.store_assignment(assignment)
  end

  task :remove_assignment => 'environment' do
    experiment = Experiments[require_env('experiment')] or raise "Experiment not found"
    experiment.remove_subject_identifier(require_env('subject'))
  end
end

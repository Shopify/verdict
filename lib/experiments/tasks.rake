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
    raise "Provide the experiment handle as env variable" if ENV['experiment'].blank?
    raise "Provide the subject identifier as env variable" if ENV['subject'].blank?

    experiment = Experiments[ENV['experiment']] or raise "Experiment not found"
    assignment = experiment.lookup_assignment_for_identifier(ENV['subject'])

    if assignment.nil?
      puts "Subject #{ENV['subject']} is not assigned to experiment #{experiment.handle} yet."
    elsif assignment.qualified?
      puts "Subject #{ENV['subject']} is assigned to group `#{assignment.group.handle}`"
    else
      puts "Subject #{ENV['subject']} is unqualified for experiment #{experiment.handle}"
    end
  end

  task :wrapup => 'environment' do
    raise "Provide the experiment handle as env variable" if ENV['experiment'].blank?

    experiment = Experiments[ENV['experiment']] or raise "Experiment not found"
    experiment.wrapup
  end

  task :assign_manually => 'environment' do
    raise "Provide the experiment handle as env variable" if ENV['experiment'].blank?
    raise "Provide the group handle as env variable" if ENV['group'].blank?
    raise "Provide the subject identifier as env variable" if ENV['subject'].blank?

    experiment = Experiments[ENV['experiment']] or raise "Experiment not found"
    group = experiment.group(ENV['group']) or raise "Group not found"
    assignment = experiment.subject_assignment(ENV['subject'], group, false)
    experiment.store_assignment(assignment)
  end

  task :disqualify => 'environment' do
    raise "Provide the experiment handle as env variable" if ENV['experiment'].blank?
    raise "Provide the subject identifier as env variable" if ENV['subject'].blank?

    experiment = Experiments[ENV['experiment']] or raise "Experiment not found"
    assignment = experiment.subject_assignment(ENV['subject'], nil, false)
    experiment.store_assignment(assignment)
  end

  task :remove => 'environment' do
    raise "Provide the experiment handle as env variable" if ENV['experiment'].blank?
    raise "Provide the subject identifier as env variable" if ENV['subject'].blank?

    experiment = Experiments[ENV['experiment']] or raise "Experiment not found"
    experiment.remove_subject_identifier(ENV['subject'])
  end
end

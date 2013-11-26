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

  task :lookup => 'environment' do
    raise "Provide the experiment name as env variable" if ENV['experiment'].blank?
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
    raise "Provide the experiment name as env variable" if ENV['experiment'].blank?
    experiment = Experiments[ENV['experiment']] or raise "Experiment not found"
    experiment.wrapup
  end
end

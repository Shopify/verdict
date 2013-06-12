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
end

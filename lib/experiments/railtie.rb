class Experiments::Railtie < Rails::Railtie
  initializer "experiments.configure_rails_initialization" do 
    Experiments.logger = Rails.logger
    Experiments.directory = Rails.root.join('app', 'experiments')
  end

  rake_tasks do
    load File.expand_path("./tasks.rake", File.dirname(__FILE__))
  end
end

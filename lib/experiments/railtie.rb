class Experiments::Railtie < Rails::Railtie
  initializer "experiments.configure_rails_initialization" do 
    Experiments.logger = Rails.logger
    Experiments.directory = Rails.root.join('app', 'experiments')
  end
end

class Experiments::Railtie < Rails::Railtie
  initializer "experiments.configure_rails_initialization" do |app|
    Experiments.default_logger = Rails.logger
    Experiments.directory = Rails.root.join('app', 'experiments')

    app.config.eager_load_paths -= [Experiments.directory.to_s]
  end

  rake_tasks do
    load File.expand_path("./tasks.rake", File.dirname(__FILE__))
  end
end

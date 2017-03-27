class Verdict::Railtie < Rails::Railtie
  initializer "experiments.configure_rails_initialization" do |app|
    Verdict.default_logger = Rails.logger
    Verdict.directory = Rails.root.join('app', 'experiments')

    app.config.eager_load_paths -= [Verdict.directory.to_s]
    # Re-freeze eager load paths to ensure they blow up if modified at runtime, as Rails does
    app.config.eager_load_paths.freeze
  end

  rake_tasks do
    load File.expand_path("./tasks.rake", File.dirname(__FILE__))
  end
end

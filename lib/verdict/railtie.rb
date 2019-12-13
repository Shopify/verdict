class Verdict::Railtie < Rails::Railtie
  initializer "experiments.configure_rails_initialization" do |app|
    Verdict.default_logger = Rails.logger
    Verdict.directory ||= Rails.root.join('app', 'experiments')
  end

  config.to_prepare do
    # Clear Verdict's cache in order to avoid "A copy of ... has been removed from the module tree but is still active!"
    Verdict.clear_repository_cache
    Verdict.discovery
  end

  rake_tasks do
    load File.expand_path("./tasks.rake", File.dirname(__FILE__))
  end
end

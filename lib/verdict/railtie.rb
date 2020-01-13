class Verdict::Railtie < Rails::Railtie
  initializer "experiments.configure_rails_initialization" do |app|
    app.config.eager_load_namespaces << Verdict

    Verdict.default_logger = Rails.logger

    Verdict.directory ||= Rails.root.join('app', 'experiments')

    if Rails.gem_version >= Gem::Version.new('6.0.0') && Rails.autoloaders.zeitwerk_enabled?
      Rails.autoloaders.main.ignore(Verdict.directory)
    else
      app.config.eager_load_paths -= Dir[Verdict.directory.to_s]

      # Re-freeze eager load paths to ensure they blow up if modified at runtime, as Rails does
      app.config.eager_load_paths.freeze
    end
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

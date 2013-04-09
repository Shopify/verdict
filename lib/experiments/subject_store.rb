module Experiments::SubjectStore

  class Base
    # Should return true if stored successfully
    def set(experiment_name, subject_identifier, qualified, segment)
      raise NotImplementedError
    end

    # Should return nil if not found in store
    # Should return {:qualified => <bool>, :segment => <symbol> } when found.
    def get(experiment_name, subject_identifier)
      raise NotImplementedError
    end
  end

  class Dummy < Base
    def set(experiment_name, subject_identifier, qualified, segment)
      false
    end

    def get(experiment_name, subject_identifier)
      nil
    end
  end

  class Memory < Base
    def initialize
      @store = {}
    end

    def set(experiment_name, subject_identifier, qualified, segment)
      @store[experiment_name] ||= {}
      @store[experiment_name][subject_identifier] = { :qualified => qualified, :segment => segment }
      true
    end

    def get(experiment_name, subject_identifier)
      experiment_store = @store[experiment_name] || {}
      experiment_store[subject_identifier]
    end
  end
end

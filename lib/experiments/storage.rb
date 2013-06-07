module Experiments::Storage

  class Base
    # Should return true if stored successfully
    def store_assignment(experiment, subject_identifier, assignment)
      raise NotImplementedError
    end

    # Should return nil if not found in store
    # Should return an Assignment instance
    def retrieve_assignment(experiment, subject_identifier)
      raise NotImplementedError
    end
  end

  class Dummy < Base
    def store_assignment(experiment, subject_identifier, assignment)
      false
    end

    def retrieve_assignment(experiment, subject_identifier)
      nil
    end
  end

  class Memory < Base
    def initialize
      @store = {}
    end

    def store_assignment(experiment, subject_identifier, assignment)
      @store[experiment.name] ||= {}
      @store[experiment.name][subject_identifier] = assignment.returning
      true
    end

    def retrieve_assignment(experiment, subject_identifier)
      experiment_store = @store[experiment.name] || {}
      experiment_store[subject_identifier]
    end
  end
end

module Experiments::Storage

  class Base
    # Should return true if stored successfully
    def store_assignment(experiment_name, subject_identifier, qualified, segment)
      raise NotImplementedError
    end

    # Should return nil if not found in store
    # Should return {:qualified => <bool>, :segment => <symbol> } when found.
    def retrieve_assignment(experiment_name, subject_identifier)
      raise NotImplementedError
    end
  end

  class Dummy < Base
    def store_assignment(experiment_name, subject_identifier, qualified, segment)
      false
    end

    def retrieve_assignment(experiment_name, subject_identifier)
      nil
    end
  end

  class Memory < Base
    def initialize
      @store = {}
    end

    def store_assignment(experiment_name, subject_identifier, qualified, group)
      @store[experiment_name] ||= {}
      @store[experiment_name][subject_identifier] = Experiments::Assignment.new(returning: true, qualified: qualified, group: group)
      true
    end

    def retrieve_assignment(experiment_name, subject_identifier)
      experiment_store = @store[experiment_name] || {}
      experiment_store[subject_identifier]
    end
  end
end

module Experiments::Storage

  class Dummy

    # Should store the assignments to allow quick lookups.
    # - Assignments should be unique on the combination of 
    #   `assignment.experiment.handle` and `assignment.subject_identifier`.
    # - The main property to store is `group.handle`
    # - Should return true if stored successfully.
    def store_assignment(assignment)
      false
    end

    # Should do a fast lookup of an assignment of the subject for the given experiment.
    # - Should return nil if not found in store
    # - Should return an Assignment instance otherwise.
    def retrieve_assignment(experiment, subject_identifier)
      nil
    end
  end

  class Memory
    def initialize
      @store = {}
    end

    def store_assignment(assignment)
      @store[assignment.experiment.handle] ||= {}
      @store[assignment.experiment.handle][assignment.subject_identifier] = assignment.returning
      true
    end

    def retrieve_assignment(experiment, subject_identifier)
      experiment_store = @store[experiment.handle] || {}
      experiment_store[subject_identifier]
    end
  end
end

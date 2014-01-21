require 'digest/md5'

# Base class of all segmenters.
#
# The segmenter is responsible for assigning subjects to groups. You can
# implement any assignment strategy you like by subclassing this class and
# using it in your experiment.
#
# - You should implement the register_group method for the experiment definition DSL
#   to make the system aware of the groups that the segmenter could return. 
# - The verify! method is called after all the groups have been defined, so it can
#   detect internal inconsistencies in the group definitions.
# - The assign method is where your assignment magic lives.
class Verdict::Segmenter

  # The experiment to which this segmenter is associated
  attr_reader :experiment

  # A hash of the groups that are defined in this experiment, indexed by their
  # handle. The assign method should return one of the groups in this hash
  attr_reader :groups

  def initialize(experiment)
    @experiment = experiment
    @groups = {}
  end

  # DSL method to register a group. It calls the register_group method of the
  # segmenter implementation
  def group(handle, *args, &block)
    group = register_group(handle, *args)
    @groups[group.handle] = group
    group.instance_eval(&block) if block_given?
  end

  # The group method is called from the experiment definition DSL.
  # It should register a new group to the segmenter, with the given handle.
  #
  # - The handle parameter is a symbol that uniquely identifies the group within
  #   this experiment.
  # - The return value of this method should be a Verdict::Group instance.
  def register_group(handle, *args)
    raise NotImplementedError
  end

  # The verify! method is called after all the groups have been defined in the
  # experiment definition DSL. You can run any consistency checks in this method, 
  # and if anything is off, you can raise a Verdict::SegmentationError to
  # signify the problem.
  def verify!
    # noop by default
  end

  # The assign method is called to assign a subject to one of the groups that have been defined
  # in the segmenter implementation.
  #
  # - The identifier parameter is a string that uniquely identifies the subject.
  # - The subject paramater is the  subject instance that was passed to the framework,
  #   when the application code calls Experiment#assign or Experiment#switch.
  # - The context parameter is an object that was passed to the framework, you can use this
  #   object any way you like in your segmenting logic.
  #
  # This method should return the Verdict::Group instance to which the subject should be assigned.
  # This instance should be one of the group instance that was registered in the definition DSL.
  def assign(identifier, subject, context)
    raise NotImplementedError
  end


  # This method is called whenever a subjects converts to a goal, i.e., when Experiment#convert
  # is called. You can use this to implement a feedback loop in your segmenter.
  #
  # - The identifier parameter is a string that uniquely identifies the subject.
  # - The subject paramater is the  subject instance that was passed to the framework,
  #   when the application code calls Experiment#assign or Experiment#switch.
  # - The conversion parameter is a Verdict::Conversion instance that describes what
  #   goal the subject converted to.
  #
  # The return value of this method is not used.
  def conversion_feedback(identifier, subject, conversion)
    # noop by default
  end
end

require 'verdict/fixed_percentage_segmenter'

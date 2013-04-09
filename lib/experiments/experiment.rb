require 'digest/md5'

class Experiments::Experiment
  class AssignmentError < StandardError; end 
  
  attr_reader :name, :groups

  def initialize(name, &block)
    @name = name
    @total_percentage_assigned = 0
    @groups = {}
    yield self
    
    raise AssignmentError, "Should assign exactly 100% of the cases, but groups add up to #{@total_percentage_assigned}%." if @total_percentage_assigned != 100

  end
  
  def percentage(n, label)
    n = n.to_i
    @groups[label] = @total_percentage_assigned ... (@total_percentage_assigned + n)
    @total_percentage_assigned += n
  end
  
  def half(label)
    self.percentage(50, label)
  end
  
  def rest(label)
    self.percentage(100 - @total_percentage_assigned, label)
  end

  def active_for?(object)
    true
  end

  def group_for(object_or_id)
    return unless active_for?(object_or_id)
    identifier = object_or_id.respond_to?(:id) ? object_or_id.id : object_or_id
    group_for_id(identifier)
  end

  protected

  # The identifier should be something unique and immutable
  def group_for_id(identifier)
    percentile = calculate_case_percentile(identifier)
    label, range = groups.find {|label, range| range.include?(percentile)}
    unless label
      raise "Could not get group for seed #{identifier.inspect}"
    end
    Experiments.logger.info "[#{name}] subject id #{identifier.inspect} is in group #{label.inspect}"
    label
  end

  def calculate_case_percentile(identifier)
    raise ArgumentError.new("identifier must not be nil") if identifier.nil?
    Digest::MD5.hexdigest("#{@name}#{identifier}").to_i(16) % 100
  end
end

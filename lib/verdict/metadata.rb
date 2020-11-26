module Verdict::Metadata
  def self.included(klass)
    klass.class_attribute :metadata, default: {}
    klass.extend ClassMethods
  end

  module ClassMethods
    def name_metadata(new_name = nil)
      return @metadata[:name] if new_name.nil?
      self.metadata = metadata.merge(name: new_name)
    end

    def description(new_description = nil)
      @metadata ||= {}
      return @metadata[:description] if new_description.nil?
      @metadata[:description] = new_description
    end

    def screenshot(new_screenshot = nil)
      @metadata ||= {}
      return @metadata[:screenshot] if new_screenshot.nil?
      @metadata[:screenshot] = new_screenshot
    end

    def owner(new_owner = nil)
      @metadata ||= {}
      return @metadata[:owner] if new_owner.nil?
      @metadata[:owner] = new_owner
    end
  end
end

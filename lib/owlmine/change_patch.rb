module Owlmine
  module ChangePatch
    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)
      base.class_eval do
        unloadable
        after_create :generate_ontology_change
        after_destroy :remove_ontology_change
      end
    end

    module ClassMethods
    end

    module InstanceMethods
      def generate_ontology_change
        self.reload
        OntologyChange.generate(self)
        return true
      end

      def remove_ontology_change
        OntologyChange.destroy(:change_id => self.id) if self.id
      end
    end
  end
end
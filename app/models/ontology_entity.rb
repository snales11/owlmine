class OntologyEntity < ActiveRecord::Base
  unloadable
  has_many :ontology_entity_changes, :dependent => :restrict
  has_many :ontologies, :through => :ontology_entity_changes
  validates_presence_of :uri
end

class OntologyChange < ActiveRecord::Base
  unloadable
  belongs_to :change
  has_many :ontology_raw_changes
  has_many :ontology_statements, :through => :ontology_raw_changes 
  has_many :ontology_entity_changes
  has_many :ontology_entities, :through => :ontology_entity_changes
  validates_associated :change
end

class Change
  has_one :ontology, :dependent => :destroy
end

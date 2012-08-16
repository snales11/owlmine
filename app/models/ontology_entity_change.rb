class OntologyEntityChange < ActiveRecord::Base
  unloadable
  belongs_to :ontology_change
  belongs_to :ontology_entity
  has_and_belongs_to_many :ontology_raw_changes, :autosave => true
  validates_associated :ontology_change
  validates_associated :ontology_entity
  validates_inclusion_of :action, :in => %w(? - + *)
end

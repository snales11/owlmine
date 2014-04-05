class OntologyRawChange < ActiveRecord::Base
  unloadable
  belongs_to :ontology_change
  belongs_to :ontology_statement
  has_and_belongs_to_many :ontology_entity_changes
  validates_associated :ontology_change
  validates_associated :ontology_statement
  validates_inclusion_of :action, :in => %w(- + * #)
end

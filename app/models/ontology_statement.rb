class OntologyStatement < ActiveRecord::Base
  unloadable
  has_many :ontology_raw_changes, :dependent => :restrict
  has_many :ontologies, :through => :ontology_raw_changes 
  validates_presence_of :type
  validates_presence_of :args
end

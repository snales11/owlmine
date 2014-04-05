class NamespacePrefix < ActiveRecord::Base
  unloadable
  belongs_to :ontology_change
  validates_associated :ontology_change
end

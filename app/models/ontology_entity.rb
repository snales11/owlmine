require 'uri'

class OntologyEntity < ActiveRecord::Base
  unloadable
  has_many :ontology_entity_changes, :dependent => :restrict
  has_many :ontology_changes, :through => :ontology_entity_changes
  validates_presence_of :uri
  
  def shortname
    puts @uri
    uri = URI(@uri)
    if uri.fragment
      uri.fragment
    else
      uri.path.split('/')[-1]
    end
  end
end

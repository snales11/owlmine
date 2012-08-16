module Redmine
  module Scm
    module Adapters
      class MercurialAdapter < AbstractAdapter
        def cat_to_file(path, identifier, filename)
          p = CGI.escape(scm_iconv(@path_encoding, 'UTF-8', without_leading_slash(path)))
          hg 'cat', '-r', CGI.escape(hgrev(identifier)), '-o', filename, hgtarget(p)
        rescue HgCommandAborted
          nil
        end
      end
      
      class GitAdapter < AbstractAdapter
        def cat_to_file(path, identifier, filename)
          if identifier.nil?
            identifier = 'HEAD'
          end
          cmd_args = %w|show --no-color|
          cmd_args << "#{identifier}:#{scm_iconv(@path_encoding, 'UTF-8', path)}"
          cmd_args << ">#{filename}"
          git_cmd(cmd_args)
        rescue ScmCommandAborted
          nil
        end
      end
    end
  end
end

class OntologyChange < ActiveRecord::Base
  unloadable
  belongs_to :change
  has_many :ontology_raw_changes
  has_many :ontology_statements, :through => :ontology_raw_changes 
  has_many :ontology_entity_changes
  has_many :ontology_entities, :through => :ontology_entity_changes
  validates_associated :change
  
  def self.generate(change)
    return nil unless change.path =~ /\.(owl|rdf|ttl|n3|)$/
    changeset = change.changeset
    return nil unless changeset.parents.length <= 1
    parent_changeset = changeset.parents[0]
    repo = changeset.repository
    ontology_change = OntologyChange.new(:change_id => change.id)
    ontology_change.save
    tempfile_parent = Tempfile.new('owlmine-parent')
    tempfile_child = Tempfile.new('owlmine-child')
    begin
      tempfile_parent.close
      tempfile_child.close
      repo.scm.cat_to_file(change.path, changeset.identifier, tempfile_child.path)
      if parent_changeset != nil
        repo.scm.cat_to_file(change.path, parent_changeset.identifier, tempfile_parent.path)
      end
      output = `owl2diff #{tempfile_parent.path} #{tempfile_child.path} --by-entity --format compact --iriformat full`
      #print output
      sections = output.split("\n\n")
      changes_without_entity = sections.shift
      for section in sections
        next if section == ''
        changes = section.strip.split("\n")
        entity_line = changes.shift
        next if entity_line == nil
        entity_change_action = entity_line[0]
        _, entity_type_uri = entity_line.split(' ', 2)
        entity_type, entity_uri = entity_type_uri.split(': ', 2)
        puts "#{entity_change_action} #{entity_type}: #{entity_uri}"
        entity = OntologyEntity.find_or_create_by_entity_type_and_uri(entity_type, entity_uri)
        entity_change = OntologyEntityChange.find_or_create_by_ontology_change_id_and_ontology_entity_id_and_action(
                                                               ontology_change.id,             entity.id,    entity_change_action)
        for change_text in changes
          raise "Bad change formatting: #{change_text}" unless change_text[1] == ' '
          action = change_text[0]
          raise "Unknown action #{action}" unless ['+', '-'].include? action
          statement_text = change_text[2..-1]
          print action
          statement = OntologyStatement.find_or_create_by_text(statement_text)
          orc = OntologyRawChange.find_or_create_by_ontology_change_id_and_ontology_statement_id_and_action(
                                                    ontology_change.id,    statement.id,             action)
          entity_change.ontology_raw_changes << orc           
        end
        entity_change.save
        puts
      end
    ensure
      tempfile_parent.unlink
      tempfile_child.unlink      
    end
    ontology_change.save
    return ontology_change
  end
end

#class Change
#  has_one :ontology_change, :dependent => :destroy 
#  after_save do
#    OntologyChange.generate(self)
#    return true
#  end
#end


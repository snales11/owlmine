#encoding: UTF-8

module Redmine
  module Scm
    module Adapters
      class AbstractAdapter
        protected #abstract
        def _cat_to_file(path, identifier, filename)
        end

        public
        def cat_to_file(path, identifier, filename)
          logger.info "Exporting #{identifier}:#{path} to #{filename}"
          _cat_to_file(path, identifier, filename)
        rescue ScmCommandAborted
          raise
        end
      end

      class MercurialAdapter < AbstractAdapter
        def _cat_to_file(path, identifier, filename)
          p = CGI.escape(scm_iconv(@path_encoding, 'UTF-8', without_leading_slash(path)))
          hg 'cat', '-r', CGI.escape(hgrev(identifier)), '-o', filename, hgtarget(p)
        end
      end

      class GitAdapter < AbstractAdapter
        def _git_cmd(args, outfile, options = {}, &block)
          repo_path = root_url || url
          full_args = ['--git-dir', repo_path]
          if self.class.client_version_above?([1, 7, 2])
            full_args << '-c' << 'core.quotepath=false'
            full_args << '-c' << 'log.decorate=no'
          end
          full_args += args
          ret = shellout(
              self.class.sq_bin + ' ' + full_args.map { |e| shell_quote e.to_s }.join(' ') + ' >' + shell_quote(outfile),
              options,
              &block
          )
          if $? && $?.exitstatus != 0
            raise ScmCommandAborted, "git exited with non-zero status: #{$?.exitstatus}"
          end
          ret
        end

        def _cat_to_file(path, identifier, filename)
          if identifier.nil?
            identifier = 'HEAD'
          end
          cmd_args = %w|show --no-color|
          cmd_args << "#{identifier}:#{scm_iconv(@path_encoding, 'UTF-8', path)}"
          _git_cmd(cmd_args, filename)
=begin
          File.open(filename, 'w') do |f|
            f.set_encoding("ASCII-8BIT") if f.respond_to?(:set_encoding)
            git_cmd(cmd_args) do |io|
              io.each_line do |line|
                f.write(line)
              end
            end
          end
=end
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
  has_many :namespace_prefixes
  validates_associated :change


  def self.generate(change)
    return nil unless change.action == 'M'
    files_re = Setting.plugin_owlmine['files']
    return nil unless change.path =~ files_re
    changeset = change.changeset
    return nil if changeset.parents.length == 0
    ontology_change = OntologyChange.new(:change_id => change.id)
    transaction do
      parent_changeset = changeset.parents[0]
      repo = changeset.repository
      ontology_change.save
      tempfile_parent = Tempfile.new("owlmine-parent-#{parent_changeset.id}-#{File.basename(change.path)}")
      tempfile_child = Tempfile.new("owlmine-child-#{changeset.id}-#{File.basename(change.path)}")
      begin
        tempfile_parent.close
        tempfile_child.close
        if parent_changeset != nil
          repo.scm.cat_to_file(change.path, parent_changeset.identifier, tempfile_parent.path)
        end
        repo.scm.cat_to_file(change.path, changeset.identifier, tempfile_child.path)
        cmd = "owl2diff #{tempfile_parent.path} #{tempfile_child.path} -e -c -p -f compact -i full"
        output = IO.popen(cmd, 'r+').read #:ASCII-8BIT
        logger.debug output
        if output.start_with? "\n" and !output.start_with? "\n\n"
          output = "\n" + output
        end
        sections = output.split("\n\n")
        prefixes_text = sections.shift
        if prefixes_text
          for prefixline in prefixes_text.split("\n")
            logger.debug "Prefix: #{prefixline}"
            prefix, namespace = prefixline.split("=")
            NamespacePrefix.find_or_create_by_ontology_change_id_and_prefix_and_namespace(
                                              ontology_change.id,    prefix,    namespace)
          end
        end

        changes_without_entity_text = sections.shift

        if changes_without_entity_text
          for change_text in changes_without_entity_text.split("\n")
            next if change_text == ''
            raise "Bad change formatting: #{change_text}" unless change_text[1] == ' '
            action = change_text[0]
            raise "Unknown action #{action}" unless ['+', '-', '*', '#'].include? action
            statement_text = change_text[2..-1]
            # logger.debug action
            statement = OntologyStatement.find_or_create_by_text(statement_text)
            OntologyRawChange.find_or_create_by_ontology_change_id_and_ontology_statement_id_and_action(
                                                ontology_change.id,    statement.id,             action)         
          end
        end
        for section in sections
          next if section == ''
          changes = section.strip.split("\n")
          entity_line = changes.shift
          next if entity_line == nil
          entity_change_action = entity_line[0]
          _, entity_type_uri = entity_line.split(' ', 2)
          entity_type, entity_uri = entity_type_uri.split(': ', 2)
          logger.debug "#{entity_change_action} #{entity_type}: #{entity_uri}"
          entity = OntologyEntity.find_or_create_by_entity_type_and_uri(entity_type, entity_uri)
          entity.save
          entity_change = OntologyEntityChange.find_or_create_by_ontology_change_id_and_ontology_entity_id_and_action(
                                                                 ontology_change.id,             entity.id,    entity_change_action)
          for change_text in changes
            raise "Bad change formatting: #{change_text}" unless change_text[1] == ' '
            action = change_text[0]
            raise "Unknown action #{action}" unless ['+', '-'].include? action
            statement_text = change_text[2..-1]
            logger.debug action
            statement = OntologyStatement.find_or_create_by_text(statement_text)
            orc = OntologyRawChange.find_or_create_by_ontology_change_id_and_ontology_statement_id_and_action(
                                                      ontology_change.id,    statement.id,             action)
            entity_change.ontology_raw_changes << orc           
          end
          entity_change.save
          logger.debug ""
        end
        # debug mode: keep files if something goes wrong
        tempfile_parent.unlink
        tempfile_child.unlink
      rescue ArgumentError => e
        logger.info "Skipping invalid revison"
        return nil
      rescue
        f = File.open("last-output", "w")
        f.write(output)
        f.close
        raise
      ensure

      end
      ontology_change.save
    end
    return ontology_change
  end

  def format_statement(statement, iriformat=:qname, layout=:indented)

    case layout
    when :parenthesis
      text = statement.text
    when :indented
      text = statement.indented_text
    end

    case iriformat
    when :full
      # it is full by default
    when :qname
      for np in namespace_prefixes
        if np.prefix == ':'
          text.gsub!(/<#{np.namespace}([^>]+)>/, "\\1")
        else
          text.gsub!(/<#{np.namespace}([^>]+)>/, "#{np.prefix}\\1")
        end
      end
    when :simple
      text.gsub!(/<.*[#\/]([^>]+)>/, '\1')
    end
    text
  end


  def format_entity(entity, iriformat=:qname)
    text = entity.uri
    case iriformat
    when :full
    when :qname
      for np in namespace_prefixes
        text.gsub!(/<#{np.namespace}([^>]+)>/, "#{np.prefix}\\1")
      end
    when :simple
      text.gsub!(/<.*[#\/]([^>]+)>/, '\1')
    end
    text
  end

  
end

# class Change
#   has_one :ontology_change, :dependent => :destroy 
#   after_create do
#     self.reload
#     OntologyChange.generate(self)
#     return true
#   end
# end

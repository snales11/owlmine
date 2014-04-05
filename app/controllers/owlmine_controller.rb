require 'tempfile'

class OwlmineController < ApplicationController
  unloadable
  
  menu_item :owlmine
  
  #before_filter :authorize
  before_filter :find_project_by_project_id
  before_filter :find_project_repository, :only => [:diff]

  REV_PARAM_RE = %r{\A[a-f0-9]*\Z}i

  def find_project_repository
    @project = Project.find(params[:project_id])
    if params[:repository_id].present?
      @repository = @project.repositories.find_by_identifier_param(params[:repository_id])
    else
      @repository = @project.repository
    end
    (render_404; return false) unless @repository
    @path = params[:path].is_a?(Array) ? params[:path].join('/') : params[:path].to_s
    @path << '.' + params[:ext] if params[:ext].present? 
    @rev = params[:rev].blank? ? @repository.default_branch : params[:rev].to_s.strip
    @rev_to = params[:rev_to]

    unless @rev.to_s.match(REV_PARAM_RE) && @rev_to.to_s.match(REV_PARAM_RE)
      if @repository.branches.blank?
        raise InvalidRevisionParam
      end
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  rescue InvalidRevisionParam
    show_error_not_found
  end


  def entities
    files_re = Setting.plugin_owlmine['files']
    # generate ontology changes
    @entities = [] 
    for repo in @project.repositories
      logger.info "Repo: #{repo.url}"
      for changeset in repo.changesets.reverse
        logger.info "Changeset: #{changeset.id} by #{changeset.committer} at #{changeset.committed_on}"
        # logger.debug "#{changeset.comments}"
        next unless changeset.parents.length > 0
        parent = changeset.parents[0]
        logger.debug "Parent: #{parent.id} by #{parent.committer} at #{parent.committed_on}"
        # logger.debug "#{parent.comments}""
        for change in changeset.filechanges
          if change.path !~ files_re
            logger.debug "#{change.action} #{change.path}"
            next
          end
          logger.info "#{change.action} #{change.path}"
          ontology_change = OntologyChange.find_by_change_id(change.id)
          if not ontology_change
            ontology_change = OntologyChange.generate(change)
          end
          if ontology_change
            for entity_change in ontology_change.ontology_entity_changes
              @entities << entity_change.ontology_entity
            end
          end
        end
      end     
    end
    @entities_by_type = @entities.group_by { |entity| entity.entity_type }
  end

  def entity
    entity_id = params[:entity_id]
    @entity = OntologyEntity.find_by_id(entity_id)
    @entity = OntologyEntity.find_by_uri(entity_id) unless @entity
    (render_404; return false) unless @entity
  end


  def diff
    @changeset = @repository.find_changeset_by_name(@rev)
    @changeset_to = @rev_to ? @repository.find_changeset_by_name(@rev_to) : nil
    @diff_format_revisions = @repository.diff_format_revisions(@changeset, @changeset_to)
    puts "#{@changeset.id} #{@path}"
    @change = Change.find_by_changeset_id_and_path(@changeset.id, @path)
    @change = Change.find_by_changeset_id_and_path(@changeset.id, @path.with_leading_slash) unless @change
    (render_404; return false) unless @change
    @ontology_change = OntologyChange.find_by_change_id(@change.id)
  end
  
end

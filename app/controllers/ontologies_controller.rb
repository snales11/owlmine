class OntologiesController < ApplicationController
  unloadable


  def index
    # suppose we have project_id
    repositories = Repository.find_all_by_project_id(project_id)
    @ontologies = []
    for repo in repositories
      # ontologies << repo.entries that have raw changes     
    end
  end

end

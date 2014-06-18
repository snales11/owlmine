# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

get 'projects/:project_id/owl_entities', :to => 'owlmine#entities'
get 'projects/:project_id/owl_entity/:entity_id', :to => 'owlmine#entity'
get 'projects/:project_id/repository/revisions/:rev/owl2diff(/*path(.:ext))', :to => 'owlmine#diff'
get 'projects/:project_id/repository/owl2diff(/*path(.:ext))', :to => 'owlmine#diff'
# TODO: link to this route from projects/:project_id/repository/changes/(/*path(.:ext))

require 'redmine'
require 'haml'
require_dependency 'owlmine/hooks'

ActionDispatch::Callbacks.to_prepare do 
  require_dependency 'change'
  unless Change.included_modules.include? Owlmine::ChangePatch
    Change.send(:include, Owlmine::ChangePatch)
  end
end

Redmine::Plugin.register :owlmine do
  name 'Owlmine plugin'
  author 'utapyngo'
  description 'Shows history of OWL ontologies and OWL entities'
  version '0.1'
  
  #permission :ontologies, { :ontologies => [:index] }, :public => true

  settings(:partial => 'settings/owlmine_settings',
           :default => {
             'files' => /\.(owl|rdf|ttl|n3)$/
           })

  menu(:project_menu,
       :owlmine,
       { :controller => 'owlmine', :action => 'entities' },
       :caption => 'OWL Entities',
       :before => :repository,
       :param => :project_id,
       :if => Proc.new {
         User.current.allowed_to?(:view_owl_entities, nil, :global => true)
       }
  )
  
  project_module :owlmine do
    permission :view_owl_entities, :owlmine => [:entities, :entity]
  end
end

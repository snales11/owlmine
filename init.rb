Redmine::Plugin.register :owlmine do
  name 'Owlmine plugin'
  author 'utapyngo'
  description 'Shows history of OWL ontologies and OWL entities'
  version '0.0.1'
  
  #permission :ontologies, { :ontologies => [:index] }, :public => true
  menu :project_menu, :owlmine, { :controller => 'owlmine', :action => 'entities' }, :caption => 'Owlmine', :before => :repository, :param => :project_id
  
  project_module :owlmine do
    permission :view_owlmine, :owlmine => [:entities, :entity]
  end
end

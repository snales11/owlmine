class CreateOntologyEntities < ActiveRecord::Migration
  def change
    create_table :ontology_entities do |t|
      t.string :uri, :null => false
    end
  end
end

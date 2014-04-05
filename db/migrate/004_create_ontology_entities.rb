class CreateOntologyEntities < ActiveRecord::Migration
  def change
    create_table :ontology_entities do |t|
      t.string :uri, :null => false
      t.string :entity_type
      t.string :label
    end
  end
end

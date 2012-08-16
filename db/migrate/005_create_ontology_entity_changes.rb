class CreateOntologyEntityChanges < ActiveRecord::Migration
  def change
    create_table :ontology_entity_changes do |t|
      t.integer :ontology_id, :null => false
      t.integer :ontology_entity_id, :null => false
      t.string :action, :null => false
    end
  end
end

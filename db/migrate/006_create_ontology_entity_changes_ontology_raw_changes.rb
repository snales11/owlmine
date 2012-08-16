class CreateOntologyEntityChangesOntologyRawChanges < ActiveRecord::Migration
  def change
    create_table :ontology_entity_changes_ontology_raw_changes do |t|
      t.integer :ontology_entity_change_id, :null => false
      t.integer :ontology_raw_change_id, :null => false
    end
  end
end

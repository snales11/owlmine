class CreateOntologyRawChanges < ActiveRecord::Migration
  def change
    create_table :ontology_raw_changes do |t|
      t.integer :ontology_change_id, :null => false
      t.integer :ontology_statement_id, :null => false
      t.string :action, :null => false
    end
  end
end

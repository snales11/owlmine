class CreateOntologyChanges < ActiveRecord::Migration
  def change
    create_table :ontology_changes do |t|
      t.integer :change_id, :null => false
    end
  end
end

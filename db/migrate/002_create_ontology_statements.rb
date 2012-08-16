class CreateOntologyStatements < ActiveRecord::Migration
  def change
    create_table :ontology_statements do |t|
      t.string :text, :null => false
    end
  end
end

class CreateOntologyStatements < ActiveRecord::Migration
  def change
    create_table :ontology_statements do |t|
      t.string :type, :null => false
      t.string :args, :null => false
    end
  end
end

class CreateNamespacePrefixes < ActiveRecord::Migration
  def change
    create_table :namespace_prefixes do |t|
      t.integer :ontology_change_id, :null => false
      t.string :prefix, :null => false
      t.string :namespace, :null => false
    end
  end
end

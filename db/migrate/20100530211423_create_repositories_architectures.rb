class CreateRepositoriesArchitectures < ActiveRecord::Migration
  def self.up
    create_table :repositories_architectures do |t|
      t.integer :repository_id
      t.integer :architecture_id

      t.timestamps
    end
  end

  def self.down
    drop_table :repositories_architectures
  end
end

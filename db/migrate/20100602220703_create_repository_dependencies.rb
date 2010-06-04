class CreateRepositoryDependencies < ActiveRecord::Migration
  def self.up
    create_table :repository_dependencies do |t|
      t.integer :repository_id
      t.integer :depends_on_id

      t.timestamps
    end
  end

  def self.down
    drop_table :repository_dependencies
  end
end

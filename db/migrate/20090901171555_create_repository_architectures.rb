class CreateRepositoryArchitectures < ActiveRecord::Migration
  def self.up
    create_table :package_distrs_architectures do |t|
      t.integer :package_distr_id
      t.integer :architecture_id

      t.timestamps
    end
    add_column :users, :architecture_id, :integer, :default => 1
  end

  def self.down
    drop_table :package_distrs_architectures
  end
end

class CreateMetacontentsDerivatives < ActiveRecord::Migration
  def self.up
    create_table :metacontents_derivatives do |t|
      t.integer :metacontent_id
      t.integer :derivative_id

      t.timestamps
    end
        
    add_column :users, :derivative_id, :integer
    add_column :distributions, :short_name, :string
    add_column :base_packages, :default_install, :boolean
    g = Distribution.find(1)
    g.short_name = "Gutsy"
    g.save
    h = Distribution.find(2)
    h.short_name = "Hardy"
    h.save
  end

  def self.down
    drop_table :metacontents_derivatives
    remove_column :users, :derivative_id, :integer
    remove_column :distributions, :short_name, :string
    remove_column :base_packages, :default_install
  end
end

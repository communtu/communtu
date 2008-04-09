class CreateCartContents < ActiveRecord::Migration
  def self.up
    create_table :cart_contents do |t|
      t.integer :cart_id
      t.integer :base_package_id
      t.timestamps
    end
  end

  def self.down
    drop_table :cart_contents
  end
end

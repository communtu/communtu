class CreateBundles < ActiveRecord::Migration
  def change
    create_table :bundles do |t|
      t.string :name
      t.string :description
      t.integer :category_id

      t.timestamps
    end
  end
end

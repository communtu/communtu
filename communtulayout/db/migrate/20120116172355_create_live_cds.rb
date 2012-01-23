class CreateLiveCds < ActiveRecord::Migration
  def change
    create_table :live_cds do |t|
      t.string :name
      t.integer :size
      t.integer :downloaded

      t.timestamps
    end
  end
end

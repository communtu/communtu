class CreateUmfrages < ActiveRecord::Migration
  def self.up
    create_table :umfrages do |t|
      t.boolean :einsteiger
      t.boolean :freak
      t.boolean :sammler
      t.boolean :musik
      t.boolean :video
      t.boolean :netz
      t.boolean :grafik
      t.boolean :spiele
      t.string :email

      t.timestamps
    end
  end

  def self.down
    drop_table :umfrages
  end
end

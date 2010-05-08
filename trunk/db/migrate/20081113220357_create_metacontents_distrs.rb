class CreateMetacontentsDistrs < ActiveRecord::Migration
  def self.up
    create_table :metacontents_distrs do |t|
      t.integer :metacontent_id
      t.integer :distribution_id

      t.timestamps
    end
  end

  def self.down
    drop_table :metacontents_distrs
  end
end

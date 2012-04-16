class AddRateToRatings < ActiveRecord::Migration
  def change
    add_column :ratings, :free_text, :text
    add_column :ratings, :rate_id, :integer
    add_column :ratings, :rater_name, :string
  
    create_table :rates do |t|
      t.column :score, :integer
    end
  
    add_index :ratings, :rate_id
    add_index :ratings, [:rateable_id, :rateable_type]
    
    ratings = (1..5).map do |score|
      Rate.create({:score => score})
    end
    
    Rating.all.each do |r|
      r.rate_id = ratings[r.rating-1].id
      begin
        r.rater_name = User.find(r.user_id).login
      rescue  
         r.rater_name = "unknown"
      end  
      r.save
    end  
  end
  
end


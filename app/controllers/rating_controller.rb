class RatingController < ApplicationController
  
  def rate
    @metapackage = Metapackage.find(params[:id])
    Rating.delete_all(["rateable_type = 'Metapackage' AND rateable_id = ? AND user_id = ?", @metapackage.id, current_user.id])
    @metapackage.add_rating Rating.new(:rating => params[:rating], :user_id => current_user.id)
  end
  
end

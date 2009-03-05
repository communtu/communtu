class RatingController < ApplicationController
  
  def rate
    @package = Package.find(params[:id])
    Rating.delete_all(["rateable_type = 'Package' AND rateable_id = ? AND user_id = ?", @package.id, @current_account.id])
    @package.add_rating Rating.new(:rating => params[:rating], :user_id => @current_account.id)
  end
  
end

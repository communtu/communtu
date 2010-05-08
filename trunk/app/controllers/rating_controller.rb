class RatingController < ApplicationController
  before_filter :is_anonymous
  
  def rate
    @metapackage = Metapackage.find(params[:id])
    Rating.delete_all(["rateable_type = 'Metapackage' AND rateable_id = ? AND user_id = ?", @metapackage.id, current_user.id])
    t = Translation.new
    @last_trans = Translation.find(:first, :order => "translatable_id DESC")
    @last_id = @last_trans.translatable_id
    @l = @last_id + 1
    t.contents = params[:rating][:comment]
    t.translatable_id = @l
    t.language_code = I18n.locale.to_s
    t.save                                
    @metapackage.add_rating Rating.new(:rating => params[:user_rating], :user_id => current_user.id, :comment => params[:rating][:comment], :comment_tid => @l)
    redirect_to :back
  end
  
end
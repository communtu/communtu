class LivecdsController < ApplicationController
  def destroy
    @cd = Livecd.find(params[:id])
    # detach live CD from user
    LivecdUser.find_all_by_livecd_id_and_user_id(@cd.id,current_user.id).each do |lu|
      lu.destroy
    end
    # are there any other users of this live CD?
    if @cd.users.empty?
      # if not, destroy live CD
      @cd.destroy
    end
    redirect_to :controller => :user_profiles, :action => :livecd
  end

  def show
    @cd = Livecd.find(params[:id])
  end

  def remaster
    @cd = Livecd.find(params[:id])
    @cd.failed = false
    @cd.generating = true
    @cd.log = nil
    @cd.save
    @cd.fork_remaster
    redirect_to :back
  end

  def index
  end
end

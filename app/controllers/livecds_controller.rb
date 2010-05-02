class LivecdsController < ApplicationController
  def destroy
    @cd = Livecd.find(params[:id])
    # detach live CD from user
    @cd.deregister(current_user)
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

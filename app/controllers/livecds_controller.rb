class LivecdsController < ApplicationController
  def destroy
    @cd = Livecd.find(params[:id])
    # detach live CD from user
    @cd.deregister(current_user)
    redirect_to '/livecds'
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

  def remaster_new
    @cd = Livecd.find(params[:id])
    @cd.generate_sources
    remaster
  end

  def index
  end
end

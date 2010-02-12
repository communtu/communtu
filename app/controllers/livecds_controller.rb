class LivecdsController < ApplicationController
  def destroy
    @cd = Livecd.find(params[:id])
    @cd.destroy
    redirect_to :back
  end

  def show
    @cd = Livecd.find(params[:id])
  end

  def remaster
    @cd = Livecd.find(params[:id])
    @cd.fork_remaster
    redirect_to :back
  end
end

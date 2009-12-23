class LivecdsController < ApplicationController
  def destroy
    @cd = Livecd.find(params[:id])
    @cd.destroy
    redirect_to :back
  end
end

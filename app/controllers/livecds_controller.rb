class LivecdsController < ApplicationController
  before_filter :login_required

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
    if !@cd.generated
      @cd.failed = false
      @cd.generating = false
      @cd.generated = false
      @cd.log = nil
      @cd.save
      # remastering done by daemon
    end
    redirect_to :back
  end

  def force_remaster
    @cd = Livecd.find(params[:id])
    @cd.generated = false
    @cd.save
    remaster
  end
  
  def remaster_new
    @cd = Livecd.find(params[:id])
    if !@cd.generate_sources.nil?
      remaster
    end
  end

  def index
  end

  def start_vm
    @cd = Livecd.find(params[:id])
    @cd.start_vm
    redirect_to livecd_path(@cd)
  end

  def stop_vm
    @cd = Livecd.find(params[:id])
    @cd.stop_vm
    redirect_to livecd_path(@cd)
  end

  def start_vm_basis
    @cd = Livecd.find(params[:id])
    @cd.start_vm_basis
    render :action => 'show'
  end

end

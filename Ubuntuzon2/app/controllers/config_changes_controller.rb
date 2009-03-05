class ConfigChangesController < ApplicationController
  
  def show
    unless logged_in?
      redirect_to '/login'
    end
    @account = @current_account
=begin
    if params[:id] != @account.id
      unless @current_account.admin?
      redirect_to '/422.html'
      end
    end
=end

    getPackageChanges
  end
  
  private

  def getPackageChanges
    
    # TODO: little dirty bastard - needs some serious cleanup ;)
    
    last_uploads = Upload.find :all, :limit => "0,2", :select => 'id', :order => 'id DESC', :conditions => { :account_id => @account }

    currentPackages = Package.find :all, :joins => :configurations, :select => 'packages.id', :conditions => [ "configurations.upload_id = ? AND configurations.account_id = ?", last_uploads[0], @account ]
    oldPackages = Package.find :all, :joins => :configurations, :select => 'packages.id', :conditions => [ "configurations.upload_id = ? AND configurations.account_id = ?", last_uploads[1], @account ]
    
    deinstalledId = oldPackages.map(&:id) - currentPackages.map(&:id)    
    installedId = currentPackages.map(&:id) - oldPackages.map(&:id)
    #@installedPackages = Package.find :all, :conditions => [ 'id' => installedId ]
    @installedPackages = Package.find_all_by_id(installedId)
    @deinstalledPackages = Package.find_all_by_id(deinstalledId)
    @allPackages = Package.find_all_by_id(currentPackages.map(&:id))
    
  end
  
end

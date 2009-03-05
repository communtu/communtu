class AccountsController < ApplicationController

  
  
  def show
    unless logged_in?
      redirect_to '/login'
    end
    @account = Account.find(params[:id])
    unless @current_account == @account
      redirect_to '/422.html'
    end
    # get the packages from the last upload by the logged in user
    @highest_upload_id = Upload.find :first, :select => 'id', :order => 'id DESC', :conditions => { :account_id => @account }
    @packages = Package.find :all, :joins => :configurations, :order => 'name ASC', :conditions => [ "configurations.upload_id = ?", @highest_upload_id ]      
  end
  
  
  def edit
    unless logged_in?
      redirect_to '/login'
    end
    @account = Account.find(params[:id])
    unless @current_account == @account
      redirect_to '/422.html'
    end
  end

  def admin_edit
    unless logged_in?
      redirect_to '/login'
    end
    unless @current_account.admin?
      redirect_to '/422.html'
    end


    @account = Account.find(params[:id])

  end

  def update
    unless logged_in?
      redirect_to '/login'
    end
    @account = Account.find(params[:id])

    respond_to do |format|
      if @account.update_attributes(params[:account])
        flash[:notice] = "Account was successfully updated"
        format.html { redirect_to(@account) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @account.errors, :status => :unprocessable_entity }
      end
    end
  end

  def create
    cookies.delete :auth_token
    # protects against session fixation attacks, wreaks havoc with 
    # request forgery protection.
    # uncomment at your own risk
    # reset_session
    @account = Account.new(params[:account])
    @account.save
    if @account.errors.empty?
      self.current_account = @account
      redirect_back_or_default('/')
      flash[:notice] = "Thanks for signing up!"
    else
      render :action => 'new'
    end
  end


end

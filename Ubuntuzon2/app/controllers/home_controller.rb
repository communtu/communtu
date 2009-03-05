class HomeController < ApplicationController

  def show
  end
  
  def admin
    logged_in?
    unless @current_account.admin?
      redirect_to '/422.html'
    end
    @packages = Package.all
    @accounts = Account.all
    
  end

end

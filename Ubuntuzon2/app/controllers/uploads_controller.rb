class UploadsController < ApplicationController
    before_filter :login_required

  def new
    unless logged_in?
      redirect_to '/login'
    end

  end

  def create
    unless logged_in?
      redirect_to '/login'
    end

    post = Upload.saveToUser(params[:upload], @current_account)
    if post
      flash[:notice] = "File has been uploaded successfully"
    else
      flash[:notice] = "Wrong file format. Only plain text files are supported!"
    end
    redirect_to suggestion_path(@current_account);
  end
end

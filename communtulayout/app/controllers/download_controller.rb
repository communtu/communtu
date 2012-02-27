class DownloadController < ApplicationController
  def selection
    @categories=Category.all
    
    begin
      @category = Category.find(params[:category])
    rescue StandardError
      @category = Category.first
    end  
      
    @bundles = @category.bundles
  end
end

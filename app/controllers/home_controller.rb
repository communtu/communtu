class HomeController < ApplicationController
  protect_from_forgery :only => [:create, :update, :destroy] 
  
  def home
  end
  
  def about
  end
  
  def derivatives
  end

  def umfrage
  end

  def danke
    @u = Umfrage.find(params[:id])
  end

  def save_umfrage    
    flash[:notice] = ""
    flash[:error] = ""
    @u = Umfrage.new(params[:data])
    @u.save
    begin
      count = 0
      err_count = 0
      params[:attachment][:packages].read.split("\n").each do |n|
        UmfragePackage.create(:umfrage_id => @u.id,:package => n)
        count += 1
        if Package.find(:first,:conditions => ["name = ?",n]).nil? then
          err_count += 1
        end
      end
      read_packages = true
      if err_count*3 > count then
        read_packages = false
        flash[:error] = "Das sieht nicht nach einer Liste von Ubuntu-Paketen aus... <br />Die Paketliste muss einen Paketnamen pro Zeile enthalten"
      end
      begin
        params[:attachment][:sources].read.split("\n").each do |n|
           UmfrageSource.create(:umfrage_id => @u.id,:source => n)
        end   
      rescue
      end
    rescue
      flash[:error] = "Es muss eine Datei mit der Paketliste (ein Paketname pro Zeile) angegeben werden"
      read_packages = false
    end
    if !read_packages then
       @u.destroy
       @u = nil
    end  
  end
end

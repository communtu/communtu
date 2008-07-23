class AdminsController < ApplicationController
  before_filter :check_administrator_role, :flash => { :notice => 'Du bist kein Administrator!' }
  
  def index
  end

  def show
  end

  def load_packages
    dist     = Distribution.find(:first)
    @new_count, @update_count = Package.import_source dist.id, dist.native
  end 
  
  def sync_package
    @repository = Repository.find(params[:id])
    @info = Package.import_source @repository  
  end

  def sync_all
    @distribution = Distribution.find(params[:id])
    @infos = @distribution.repositories.map { |r| Package.import_source r }
  end

end

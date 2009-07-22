class AdminsController < ApplicationController
  def title
    t(:controller_admins_0)
  end
  before_filter :check_administrator_role, :flash => { :notice => I18n.t(:no_admin) }
  
  def index
  end

  def show
  end
  
  def sync_package
    @repository = Repository.find(params[:id])
    @info = @repository.import_source
  end

  def sync_all
    @distribution = Distribution.find(params[:id])
    @infos = @distribution.repositories.map { |r| r.import_source }
  end

  def test_all
    @distribution = Distribution.find(params[:id])
    @infos = @distribution.repositories.map { |r| r.test_source }
  end

end

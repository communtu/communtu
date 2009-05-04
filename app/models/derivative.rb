class Derivative < ActiveRecord::Base
  has_many :metacontents_derivatives
  has_many :users
  has_many :debs, :dependent => :destroy 
  
  protected
  def after_create
    # generate new configuration file for reprepro
    Deb.write_conf_distributions
  end
  
  def after_destroy
    # generate new configuration file for reprepro
    Deb.write_conf_distributions
    # remove debian packages
    Deb.clearvanished
  end

end

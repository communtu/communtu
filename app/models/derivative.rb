# Ubuntu derivatives, like Ubuntu, Kubuntu, Xubuntu, Lubuntu
# Communtu allows the contents of bundles to depend on the derivative

class Derivative < ActiveRecord::Base
  has_many :metacontents_derivatives
  has_many :users
  has_many :debs, :dependent => :destroy
  has_many :distribution_derivatives, :dependent => :destroy
  has_many :distributions, :through => :distribution_derivatives

  DEFALUT_DERIVATIVE_NAME = "Ubuntu"

  # get default derivative
  def self.default
    return Derivative.find_by_name(DEFALUT_DERIVATIVE_NAME)
  end
  
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

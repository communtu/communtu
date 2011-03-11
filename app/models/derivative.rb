# (c) 2008-2011 by Allgemeinbildung e.V., Bremen, Germany
# This file is part of Communtu.

# Communtu is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# Communtu is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero Public License for more details.

# You should have received a copy of the GNU Affero Public License
# along with Communtu.  If not, see <http://www.gnu.org/licenses/>.

# Ubuntu derivatives, like Ubuntu, Kubuntu, Xubuntu, Lubuntu
# Communtu allows the contents of bundles to depend on the derivative

# database fields: 
# dialog: graphical dialog program, like zenity or kdialog (should be replaced with debconf standard)
# icon_file: for future use
# name
# sudo: graphical sudo command, like gksudo or kdesudo

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

  def migrate_bundles(der)
    MetacontentsDerivative.find_all_by_derivative_id(der.id).each do |mcd|
      mcd_new = mcd.clone
      mcd_new.derivative = self
      mcd_new.save
    end
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

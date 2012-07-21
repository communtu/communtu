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

# processor architectures (i.e. i386 and amd64, perhaps more in the future)
# since Ubuntu packages are architecture-specific, metapackages and the
# lists of packages they are containing are architecture-specific as well

# database fields:
# name

class Architecture < ActiveRecord::Base
  has_many :package_distrs_architectures, :dependent => :destroy
  has_many :livecds, :dependent => :destroy
  has_many :repositories_architectures, :dependent => :destroy
  has_many :repositories, :through => :repositories_architectures

  DEFAULT_ARCH_NAME = "i386"

  # extract architecture from browser info string
  def self.browser_architecture(s)
    if s.nil? then
      return nil
    end
    s1 = s.downcase
    Architecture.all.each do |a|
      case a.name
        when "i386" then n = "686"
        when "amd64" then n = "86_64"
      end
      if !s1.index(n.downcase).nil? then
        return a
      end
    end
    return nil
  end

  # extract architecture from browser info string,
  # but use default if there is nothing to extract
  def self.browser_architecture_with_default(s)
    a = Architecture.browser_architecture(s)
    if a.nil? then
      return Architecture.find_by_name(DEFAULT_ARCH_NAME)
    else
      return a
    end
  end

  # return browser info as a string
  def self.browser_info(s)
    a = Architecture.browser_architecture(s)
    if a.nil? then
      return ""
    else
      return a.name
    end
  end
  def simple_name
    case self.name
      when "i386" then "32 bit"
      when "amd64" then "64 bit"
      when "all" then "alle Architekturen"
    end
  end

end

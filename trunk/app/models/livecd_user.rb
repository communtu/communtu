class LivecdUser < ActiveRecord::Base
  belongs_to :livecd
  belongs_to :user
end

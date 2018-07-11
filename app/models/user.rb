class User < ApplicationRecord
  # Other available modules are:
  # :registerable, :confirmable, :lockable, :timeoutable, :omniauthable
  devise :database_authenticatable, :recoverable, :rememberable, :trackable, :validatable
end

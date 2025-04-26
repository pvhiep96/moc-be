class Admin < ApplicationRecord
  has_secure_password
  validates :user_name, presence: true, uniqueness: true
end

# == Schema Information
#
# Table name: admins
#
#  id              :bigint           not null, primary key
#  user_name       :string
#  password_digest :string
#  fullname        :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

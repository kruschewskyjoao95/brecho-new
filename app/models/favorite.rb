class Favorite < ApplicationRecord
  belongs_to :user
  belongs_to :product

  validates :product_id, uniqueness: { scope: :user_id, message: "já está nos seus favoritos" }
end

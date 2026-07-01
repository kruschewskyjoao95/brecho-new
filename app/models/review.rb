class Review < ApplicationRecord
  belongs_to :order
  belongs_to :buyer, class_name: "User", foreign_key: "buyer_id", optional: true
  belongs_to :seller, class_name: "User", foreign_key: "seller_id"

  validates :rating, presence: true, inclusion: { in: 1..5, message: "deve ser entre 1 e 5 estrelas" }
  validates :order_id, uniqueness: { message: "já possui uma avaliação para este pedido" }
end

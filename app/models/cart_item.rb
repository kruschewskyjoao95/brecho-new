class CartItem < ApplicationRecord
  belongs_to :cart
  belongs_to :product

  validates :quantity, presence: true, numericality: { greater_than_or_equal_to: 1 }

  def total_cents(user = nil)
    price = product.price_promo_cents || product.price_cents
    if user.present?
      offer = Offer.find_by(buyer: user, product: product, status: "accepted")
      price = offer.amount_cents if offer
    end
    quantity * price
  end

  def total(user = nil)
    total_cents(user) / 100.0
  end
end

class CartItem < ApplicationRecord
  belongs_to :cart
  belongs_to :product

  validates :quantity, presence: true, numericality: { greater_than_or_equal_to: 1 }

  def total_cents
    quantity * (product.price_promo_cents || product.price_cents)
  end

  def total
    total_cents / 100.0
  end
end

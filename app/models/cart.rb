class Cart < ApplicationRecord
  has_many :cart_items, dependent: :destroy
  has_many :products, through: :cart_items

  validates :session_token, presence: true, uniqueness: true

  def total_cents
    cart_items.includes(:product).sum { |item| item.quantity * (item.product.price_promo_cents || item.product.price_cents) }
  end

  def total
    total_cents / 100.0
  end

  def total_items_count
    cart_items.sum(:quantity)
  end
end

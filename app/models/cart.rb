class Cart < ApplicationRecord
  has_many :cart_items, dependent: :destroy
  has_many :products, through: :cart_items

  validates :session_token, presence: true, uniqueness: true

  def total_cents(user = nil)
    cart_items.includes(:product).sum do |item|
      price = item.product.price_promo_cents || item.product.price_cents
      if user.present?
        offer = Offer.find_by(buyer: user, product: item.product, status: "accepted")
        price = offer.amount_cents if offer
      end
      item.quantity * price
    end
  end

  def total(user = nil)
    total_cents(user) / 100.0
  end

  def total_items_count
    cart_items.sum(:quantity)
  end
end

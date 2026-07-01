class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :product

  validates :quantity, presence: true, numericality: { greater_than_or_equal_to: 1 }
  validates :price_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }

  def price
    price_cents / 100.0
  end

  def price=(value)
    self.price_cents = (value.to_f * 100).round
  end

  def total_cents
    quantity * price_cents
  end

  def total
    total_cents / 100.0
  end
end

class Offer < ApplicationRecord
  belongs_to :buyer, class_name: "User"
  belongs_to :product

  validates :amount_cents, presence: true, numericality: { greater_than: 0 }
  validates :status, inclusion: { in: %w[pending accepted rejected cancelled] }

  def amount
    amount_cents ? amount_cents / 100.0 : 0.0
  end

  def amount=(value)
    self.amount_cents = (value.to_f * 100).round if value.present?
  end
end

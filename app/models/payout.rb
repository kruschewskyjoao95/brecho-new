class Payout < ApplicationRecord
  belongs_to :user

  validates :amount_cents, presence: true, numericality: { greater_than: 0 }
  validates :pix_key_type, presence: true, inclusion: { in: %w[cpf email phone random key] }
  encrypts :pix_key, deterministic: true
  validates :pix_key, presence: true
  validates :status, presence: true, inclusion: { in: %w[pending paid cancelled] }

  def amount
    amount_cents / 100.0
  end

  def amount=(value)
    self.amount_cents = (value.to_f * 100).round
  end
end

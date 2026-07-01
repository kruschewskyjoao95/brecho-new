class Order < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :seller, class_name: "User", foreign_key: "seller_id", optional: true
  has_many :order_items, dependent: :destroy
  has_many :products, through: :order_items
  has_one :review, dependent: :destroy

  validates :status, presence: true, inclusion: { in: %w[pending paid shipped completed cancelled] }
  validates :shipping_status, presence: true, inclusion: { in: %w[pending_shipment shipped delivered] }
  validates :shipping_cep, presence: true
  validates :shipping_address, presence: true
  validates :payment_method, presence: true, inclusion: { in: %w[pix credit_card debit_card] }
  validates :total_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :shipping_cost_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :customer_name, presence: true
  validates :customer_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :customer_phone, presence: true

  def total
    total_cents / 100.0
  end

  def total=(value)
    self.total_cents = (value.to_f * 100).round
  end

  def shipping_cost
    shipping_cost_cents / 100.0
  end

  def shipping_cost=(value)
    self.shipping_cost_cents = (value.to_f * 100).round
  end

  def subtotal
    (total_cents - shipping_cost_cents) / 100.0
  end

  after_update :send_status_emails, if: :saved_change_to_status?

  private

  def send_status_emails
    if status == 'paid'
      OrderMailer.payment_confirmed_buyer(self).deliver_later rescue nil
      OrderMailer.sale_notification_seller(self).deliver_later rescue nil
    elsif status == 'shipped'
      OrderMailer.order_shipped_buyer(self).deliver_later rescue nil
    end
  end
end

class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :products, foreign_key: "user_id", dependent: :destroy
  has_many :sales, class_name: "Order", foreign_key: "seller_id"
  has_many :orders, dependent: :destroy
  has_many :payouts, dependent: :destroy
  has_many :reviews_as_seller, class_name: "Review", foreign_key: "seller_id", dependent: :destroy
  has_many :reviews_as_buyer, class_name: "Review", foreign_key: "buyer_id", dependent: :destroy
  has_many :favorites, dependent: :destroy
  has_many :favorite_products, through: :favorites, source: :product
  has_many :questions, dependent: :destroy
  has_many :offers, foreign_key: "buyer_id", dependent: :destroy
  has_many :received_offers, through: :products, source: :offers
  has_one_attached :avatar

  def favorited?(product)
    favorites.exists?(product_id: product.id)
  end

  def rating_average
    reviews_as_seller.average(:rating)&.to_f || 0.0
  end

  def rating_stars_count
    reviews_as_seller.count
  end

  def saldo_bloqueado
    sales_pending_cents = sales.where(status: ['paid', 'shipped']).sum("total_cents - shipping_cost_cents")
    (sales_pending_cents * 0.90) / 100.0
  end

  def saldo_disponivel
    sales_completed_cents = sales.where(status: 'completed').sum("total_cents - shipping_cost_cents")
    total_earned = (sales_completed_cents * 0.90) / 100.0
    total_withdrawn = payouts.where(status: ['pending', 'paid']).sum(:amount_cents) / 100.0
    [total_earned - total_withdrawn, 0.0].max
  end

  def free_ads_this_month
    products.where(created_at: Time.current.beginning_of_month..Time.current.end_of_month).count
  end

  def can_create_ad?
    free_ads_this_month < 2 || extra_ad_credits > 0
  end

  def consume_ad_quota!
    if free_ads_this_month > 2
      decrement!(:extra_ad_credits)
    end
  end

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true
  validates :name, presence: true
  validates :role, presence: true, inclusion: { in: %w[buyer seller admin] }

  def admin?
    role == "admin"
  end

  def seller?
    role == "seller"
  end

  def buyer?
    role == "buyer"
  end
end

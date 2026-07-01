class Product < ApplicationRecord
  belongs_to :seller, class_name: "User", foreign_key: "user_id", optional: true
  has_many_attached :images
  has_many :cart_items, dependent: :destroy
  has_many :order_items, dependent: :destroy
  has_many :favorites, dependent: :destroy
  has_many :questions, dependent: :destroy
  has_many :offers, dependent: :destroy

  validates :name, presence: true
  validates :price_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :category, presence: true
  validates :stock, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :condition, inclusion: { in: %w[new_with_tags gently_used vintage], allow_blank: true }
  validate :validate_images_count

  def condition_text
    case condition
    when "new_with_tags" then "Novo com etiqueta"
    when "gently_used" then "Gentilmente usado"
    when "vintage" then "Vintage"
    else condition
    end
  end

  # Helper para ler o preço em decimal (ex: 99.90)
  def price
    price_cents ? price_cents / 100.0 : 0.0
  end

  # Helper para escrever o preço a partir de um decimal ou string
  def price=(value)
    self.price_cents = (value.to_f * 100).round
  end

  def price_promo
    price_promo_cents ? price_promo_cents / 100.0 : nil
  end

  def price_promo=(value)
    self.price_promo_cents = value.present? ? (value.to_f * 100).round : nil
  end

  def price_installments
    # Preço parcelado em até 12x (sem juros) ou padrão
    price / 12.0
  end

  # Verifica se tem estoque
  def in_stock?
    stock > 0 && active?
  end

  private

  def validate_images_count
    if images.attached? && images.length > 5
      errors.add(:images, "Você pode enviar no máximo 5 fotos por anúncio.")
    end
  end
end

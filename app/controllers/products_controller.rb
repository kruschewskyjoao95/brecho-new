class ProductsController < ApplicationController
  allow_unauthenticated_access only: [ :index, :show, :calculate_shipping ]
  before_action :set_product, only: [ :show, :calculate_shipping ]

  def index
    @categories = Product.where(active: true).distinct.pluck(:category)
    @products = Product.where(active: true)

    if params[:query].present?
      escaped_query = ActiveRecord::Base.sanitize_sql_like(params[:query])
      q = "%#{escaped_query}%"
      @products = @products.where("products.name LIKE ? OR products.description LIKE ? OR products.brand LIKE ?", q, q, q)
    end

    if params[:category].present?
      @products = @products.where(category: params[:category])
    end

    if params[:size].present?
      @products = @products.where("products.sizes LIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(params[:size])}%")
    end

    if params[:color].present?
      @products = @products.where("products.colors LIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(params[:color])}%")
    end

    if params[:brand].present?
      @products = @products.where("products.brand LIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(params[:brand])}%")
    end

    if params[:condition].present?
      @products = @products.where(condition: params[:condition])
    end

    # Ordenação padrão do catálogo por criação recente com paginação Pagy
    @products = @products.includes(images_attachments: :blob, favorites: :user).order(created_at: :desc)
    @pagy, @products = pagy(@products, limit: 12)
  end

  def show
    # @product set by before_action
  end

  def calculate_shipping
    @cep = params[:cep]
    @street = params[:street]
    @number = params[:number]
    @shipping_options = CalculateShippingService.new(destination_cep: @cep, origin_cep: @product.seller&.cep).call

    respond_to do |format|
      format.turbo_stream
    end
  end

  private

  def set_product
    @product = Product.find(params[:id])
  end
end

class ProductsController < ApplicationController
  allow_unauthenticated_access only: [ :index, :show, :calculate_shipping ]
  before_action :set_product, only: [ :show, :calculate_shipping ]

  def index
    @categories = Product.where(active: true).distinct.pluck(:category)
    @products = Product.where(active: true)

    if params[:query].present?
      q = "%#{params[:query]}%"
      @products = @products.where("products.name LIKE ? OR products.description LIKE ? OR products.brand LIKE ?", q, q, q)
    end

    if params[:category].present?
      @products = @products.where(category: params[:category])
    end

    if params[:size].present?
      @products = @products.where("products.sizes LIKE ?", "%#{params[:size]}%")
    end

    if params[:color].present?
      @products = @products.where("products.colors LIKE ?", "%#{params[:color]}%")
    end

    if params[:brand].present?
      @products = @products.where("products.brand LIKE ?", "%#{params[:brand]}%")
    end

    if params[:condition].present?
      @products = @products.where(condition: params[:condition])
    end

    # Ordenação padrão do catálogo por criação recente
    @products = @products.order(created_at: :desc)
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

class Admin::ProductsController < Admin::BaseController
  before_action :set_product, only: [ :edit, :update, :destroy ]

  def index
    if current_user.admin?
      @products = Product.all.order(created_at: :desc)
    else
      @products = current_user.products.order(created_at: :desc)
    end
  end

  def new
    unless current_user.admin? || current_user.can_create_ad?
      redirect_to new_admin_ad_credit_path, alert: "Você atingiu o limite de 2 anúncios grátis neste mês. Adquira um anúncio extra."
      return
    end
    @product = Product.new
  end

  def create
    unless current_user.admin? || current_user.can_create_ad?
      redirect_to new_admin_ad_credit_path, alert: "Limite de anúncios excedido."
      return
    end

    @product = Product.new(product_params)
    @product.seller = current_user unless current_user.admin?

    if @product.save
      current_user.consume_ad_quota! unless current_user.admin?
      redirect_to admin_products_path, notice: "Peça '#{@product.name}' criada com sucesso!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @product.update(product_params)
      # Se o usuário marcar "remover imagens antigas" ou similar, podemos gerenciar.
      # Para simplificar, o Rails faz append se usarmos has_many_attached.
      if params[:product][:purge_images] == "1"
        @product.images.purge
      end
      
      redirect_to admin_products_path, notice: "Peça '#{@product.name}' atualizada com sucesso!"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @product.destroy
    redirect_to admin_products_path, notice: "Peça excluída com sucesso."
  end

  private

  def set_product
    if current_user.admin?
      @product = Product.find(params[:id])
    else
      @product = current_user.products.find(params[:id])
    end
  end

  def product_params
    params.require(:product).permit(
      :name, :description, :price, :price_promo,
      :category, :sizes, :colors, :stock, :active,
      :brand, :condition, images: []
    )
  end
end

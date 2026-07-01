class Admin::SalesController < Admin::BaseController
  before_action :set_sale, only: [ :show, :update ]

  def index
    query = if current_user.admin?
              Order.all.includes(:user, :seller, order_items: :product)
            else
              current_user.sales.includes(:user, :seller, order_items: :product)
            end
    @pagy, @sales = pagy(query.order(created_at: :desc), limit: 20)
  end

  def show
  end

  def update
    if @sale.update(sale_params)
      # Se adicionou o rastreamento e o pedido estava pago, avança o status
      if @sale.tracking_code.present? && @sale.status == "paid"
        @sale.update!(status: "shipped", shipping_status: "shipped")
      end
      redirect_to admin_sale_path(@sale), notice: "Pedido atualizado com sucesso!"
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def set_sale
    if current_user.admin?
      @sale = Order.find(params[:id])
    else
      @sale = current_user.sales.find(params[:id])
    end
  end

  def sale_params
    params.require(:order).permit(:tracking_code)
  end
end

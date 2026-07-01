class ReviewsController < ApplicationController
  allow_unauthenticated_access only: [ :create ]

  def create
    @order = Order.find(params[:order_id])

    if @order.status != 'completed'
      redirect_to order_path(@order), alert: "Você só pode avaliar a compra após confirmar o recebimento."
      return
    end

    if @order.review.present?
      redirect_to order_path(@order), alert: "Este pedido já foi avaliado."
      return
    end

    if authenticated?
      if @order.user != current_user
        redirect_to order_path(@order), alert: "Você não tem permissão para avaliar este pedido."
        return
      end
    else
      guest_orders = session[:guest_order_ids] || []
      unless guest_orders.include?(@order.id)
        redirect_to new_session_path, alert: "Você precisa fazer login ou ter realizado a compra como convidado para avaliar este pedido."
        return
      end
    end

    @review = @order.build_review(review_params)
    @review.buyer = current_user if authenticated?
    @review.seller = @order.seller

    if @review.save
      redirect_to order_path(@order), notice: "Obrigado! Sua avaliação foi enviada com sucesso."
    else
      redirect_to order_path(@order), alert: "Erro ao enviar avaliação: #{@review.errors.full_messages.join(', ')}"
    end
  end

  private

  def review_params
    params.require(:review).permit(:rating, :comment)
  end
end

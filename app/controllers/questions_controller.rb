class QuestionsController < ApplicationController
  # Todas as ações exigem login (comportamento padrão)

  def create
    @product = Product.find(params[:product_id])
    @question = @product.questions.build(question_params)
    @question.user = current_user

    if @question.save
      redirect_to product_path(@product), notice: "Sua pergunta foi enviada com sucesso! O vendedor será notificado."
    else
      redirect_to product_path(@product), alert: "Erro ao enviar pergunta: #{@question.errors.full_messages.join(', ')}"
    end
  end

  def answer
    @question = Question.find(params[:id])
    @product = @question.product

    # Garante que apenas o vendedor do produto (ou administrador) pode responder
    unless current_user == @product.seller || current_user.admin?
      redirect_to product_path(@product), alert: "Você não tem permissão para responder a esta pergunta."
      return
    end

    if params[:question][:answer].blank?
      redirect_to product_path(@product), alert: "A resposta não pode ficar em branco."
      return
    end

    if @question.update(answer: params[:question][:answer], answered_at: Time.current)
      redirect_to product_path(@product), notice: "Sua resposta foi enviada com sucesso!"
    else
      redirect_to product_path(@product), alert: "Erro ao enviar resposta."
    end
  end

  private

  def question_params
    params.require(:question).permit(:content)
  end
end

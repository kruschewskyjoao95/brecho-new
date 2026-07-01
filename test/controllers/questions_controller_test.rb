require "test_helper"

class QuestionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @buyer = users(:one)
    @buyer.update!(role: "buyer")
    
    @seller = users(:two)
    @seller.update!(role: "seller")
    
    @product = Product.create!(
      name: "Vestido de Seda",
      price_cents: 25000,
      category: "Vestidos",
      stock: 1,
      active: true,
      seller: @seller
    )
  end

  test "should redirect to login if unauthenticated when posting question" do
    assert_no_difference("Question.count") do
      post product_questions_path(@product), params: {
        question: { content: "Qual o comprimento?" }
      }
    end
    assert_redirected_to new_session_path
  end

  test "should create question when authenticated" do
    sign_in_as(@buyer)
    
    assert_difference("Question.count") do
      post product_questions_path(@product), params: {
        question: { content: "Qual a medida da cintura?" }
      }
    end

    assert_redirected_to product_path(@product)
    assert_equal "Sua pergunta foi enviada com sucesso! O vendedor será notificado.", flash[:notice]
    
    question = Question.last
    assert_equal "Qual a medida da cintura?", question.content
    assert_equal @buyer, question.user
    assert_equal @product, question.product
  end

  test "should not allow questions shorter than 5 characters" do
    sign_in_as(@buyer)
    
    assert_no_difference("Question.count") do
      post product_questions_path(@product), params: {
        question: { content: "Oi" }
      }
    end

    assert_redirected_to product_path(@product)
    assert_match "Erro ao enviar pergunta:", flash[:alert]
  end

  test "seller should answer a question successfully" do
    # Primeiro criamos a pergunta
    question = @product.questions.create!(user: @buyer, content: "O tecido amassa muito?")
    
    sign_in_as(@seller)
    
    patch answer_question_path(question), params: {
      question: { answer: "Não amassa quase nada, é super prático!" }
    }

    assert_redirected_to product_path(@product)
    assert_equal "Sua resposta foi enviada com sucesso!", flash[:notice]
    
    question.reload
    assert_equal "Não amassa quase nada, é super prático!", question.answer
    assert_not_nil question.answered_at
  end

  test "other users should not be allowed to answer questions" do
    question = @product.questions.create!(user: @buyer, content: "O tecido amassa muito?")
    
    # Outro comprador aleatório tenta responder
    other_user = users(:one)
    sign_in_as(other_user)
    
    patch answer_question_path(question), params: {
      question: { answer: "Eu acho que amassa" }
    }

    assert_redirected_to product_path(@product)
    assert_equal "Você não tem permissão para responder a esta pergunta.", flash[:alert]
    
    question.reload
    assert_nil question.answer
  end
end

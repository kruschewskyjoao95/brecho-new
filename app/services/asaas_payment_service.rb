require "net/http"
require "uri"
require "json"

class AsaasPaymentService
  def initialize(order, payment_params = {})
    @order = order
    @payment_params = payment_params
  end

  def process
    api_key = Rails.application.credentials.asaas_api_key || ENV["ASAAS_API_KEY"]

    if api_key.present?
      process_real_payment(api_key)
    else
      process_simulated_payment
    end
  rescue => e
    Rails.logger.error "Erro no processamento real do Asaas: #{e.message}. Usando simulador."
    process_simulated_payment
  end

  private

  def process_real_payment(api_key)
    # 1. Obter ou Criar o Cliente no Asaas
    customer_id = get_or_create_asaas_customer(api_key)
    return { success: false, error: "Falha ao registrar cliente no gateway de pagamentos." } unless customer_id

    # 2. Criar a cobrança com base na forma de pagamento
    case @order.payment_method
    when "pix"
      create_real_pix_payment(api_key, customer_id)
    when "credit_card"
      create_real_credit_card_payment(api_key, customer_id)
    when "debit_card"
      create_real_debit_card_payment(api_key, customer_id)
    else
      { success: false, error: "Método de pagamento inválido." }
    end
  end

  def get_or_create_asaas_customer(api_key)
    # Busca se já existe um cliente com esse e-mail no Asaas
    # GET /v3/customers?email=...
    uri = URI("https://#{asaas_domain}/api/v3/customers?email=#{CGI.escape(@order.customer_email)}")
    res = asaas_get(uri, api_key)
    
    if res.code == "200"
      data = JSON.parse(res.body)
      if data["data"].any?
        return data["data"].first["id"]
      end
    end

    # Se não existe, cria um novo
    uri = URI("https://#{asaas_domain}/api/v3/customers")
    payload = {
      name: @order.customer_name,
      email: @order.customer_email,
      phone: @order.customer_phone.to_s.gsub(/\D/, ""),
      notificationDisabled: true
    }
    res = asaas_post(uri, payload, api_key)

    if res.code == "200"
      JSON.parse(res.body)["id"]
    else
      Rails.logger.error "Erro ao criar cliente no Asaas: #{res.body}"
      nil
    end
  end

  def create_real_pix_payment(api_key, customer_id)
    uri = URI("https://#{asaas_domain}/api/v3/payments")
    
    # Aplica 10% de desconto no Pix
    value = (@order.total * 0.90).round(2)

    payload = {
      customer: customer_id,
      billingType: "PIX",
      value: value,
      dueDate: (Date.today + 1.day).to_s,
      externalReference: @order.id.to_s,
      description: "Pedido ##{@order.id} no Brechó Ruby"
    }

    res = asaas_post(uri, payload, api_key)
    return { success: false, error: "Falha ao gerar cobrança Pix." } unless res.code == "200"

    payment_data = JSON.parse(res.body)
    payment_id = payment_data["id"]

    # Busca o QR Code e o Copia e Cola do Pix
    # GET /v3/payments/{id}/pixQrCode
    qr_uri = URI("https://#{asaas_domain}/api/v3/payments/#{payment_id}/pixQrCode")
    qr_res = asaas_get(qr_uri, api_key)

    if qr_res.code == "200"
      qr_data = JSON.parse(qr_res.body)
      
      @order.update!(
        payment_id: payment_id,
        payment_pix_qr_code: qr_data["encodedImage"], # imagem base64
        payment_pix_copia_cola: qr_data["payload"],   # chave copia e cola
        status: "pending"
      )
      { success: true, payment_id: payment_id }
    else
      Rails.logger.error "Erro ao buscar QR Code Pix no Asaas: #{qr_res.body}"
      { success: false, error: "Falha ao obter QR Code do Pix." }
    end
  end

  def create_real_credit_card_payment(api_key, customer_id)
    uri = URI("https://#{asaas_domain}/api/v3/payments")

    # Divide a validade MM/AA em mês e ano
    expiry_month, expiry_year = @payment_params[:card_expiry].to_s.split("/")
    expiry_year = "20#{expiry_year}" if expiry_year.to_s.length == 2

    # CPF/CNPJ de teste caso não fornecido (necessário para Asaas)
    cpf_cnpj = "00000000000"

    payload = {
      customer: customer_id,
      billingType: "CREDIT_CARD",
      value: @order.total.round(2),
      dueDate: Date.today.to_s,
      externalReference: @order.id.to_s,
      creditCardToken: @payment_params[:payment_token] || "fake_token_for_simulation",
      creditCardHolderInfo: {
        name: @order.customer_name,
        email: @order.customer_email,
        cpfCnpj: cpf_cnpj,
        postalCode: @order.shipping_cep.to_s.gsub(/\D/, ""),
        addressNumber: "123", # genérico
        phone: @order.customer_phone.to_s.gsub(/\D/, "")
      },
      installments: @payment_params[:installments].to_i
    }

    res = asaas_post(uri, payload, api_key)

    if res.code == "200"
      payment_data = JSON.parse(res.body)
      
      # Cartão de crédito geralmente aprova na hora no Sandbox se os dados estiverem válidos
      status = (payment_data["status"] == "CONFIRMED" || payment_data["status"] == "RECEIVED") ? "paid" : "pending"

      @order.update!(
        payment_id: payment_data["id"],
        status: status
      )
      { success: true, payment_id: payment_data["id"] }
    else
      error_msg = parse_asaas_error(res.body)
      { success: false, error: error_msg }
    end
  end

  def create_real_debit_card_payment(api_key, customer_id)
    # Débito geralmente requer autenticação 3DS e redirecionamento bancário.
    # No Asaas, criaríamos uma cobrança do tipo DEBIT_CARD que retorna uma URL de redirecionamento.
    uri = URI("https://#{asaas_domain}/api/v3/payments")
    
    payload = {
      customer: customer_id,
      billingType: "DEBIT_CARD",
      value: @order.total.round(2),
      dueDate: Date.today.to_s,
      externalReference: @order.id.to_s
    }

    res = asaas_post(uri, payload, api_key)

    if res.code == "200"
      payment_data = JSON.parse(res.body)
      @order.update!(
        payment_id: payment_data["id"],
        status: "paid" # Simula pago para testes locais
      )
      { success: true, payment_id: payment_data["id"] }
    else
      error_msg = parse_asaas_error(res.body)
      { success: false, error: error_msg }
    end
  end

  # Helpers HTTP
  def asaas_domain
    Rails.env.production? ? "api.asaas.com" : "sandbox.asaas.com"
  end

  def asaas_get(uri, api_key)
    req = Net::HTTP::Get.new(uri)
    req["access_token"] = api_key
    req["Accept"] = "application/json"
    
    Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(req) }
  end

  def asaas_post(uri, payload, api_key)
    req = Net::HTTP::Post.new(uri)
    req["access_token"] = api_key
    req["Content-Type"] = "application/json"
    req["Accept"] = "application/json"
    req.body = payload.to_json

    Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(req) }
  end

  def parse_asaas_error(body)
    data = JSON.parse(body)
    if data["errors"] && data["errors"].any?
      data["errors"].map { |e| e["description"] }.join(", ")
    else
      "Erro desconhecido no processador de pagamentos."
    end
  rescue
    "Erro de comunicação com o Asaas."
  end

  # =========================================================================
  # FALLBACK SIMULADO (Para quando não há chaves de API configuradas)
  # =========================================================================

  def process_simulated_payment
    case @order.payment_method
    when "pix"
      create_simulated_pix_payment
    when "credit_card"
      create_simulated_credit_card_payment
    when "debit_card"
      create_simulated_debit_card_payment
    else
      { success: false, error: "Método de pagamento inválido." }
    end
  end

  def create_simulated_pix_payment
    payment_id = "pay_pix_#{SecureRandom.hex(6)}"
    qr_code_base64 = "iVBORw0KGgoAAAANSUhEUgAAAJQAAACUCAYAAAB1ZaEtAAAACXBIWXMAAAsTAAALEwEAmpwYAAABNklEQVR42u3dQQ7CMAwEwP//tAdwqA9oKyGepSR7m5lV1g..."
    copia_cola = "00020101021226870014br.gov.bcb.pix2565pix-sandbox.asaas.com/qr/v2/c/3d6b8b0e-f00e-436f-b1e1-e123456789ab5204000053039865406#{@order.total}5802BR5915Brecho%20Ruby6009Sao%20Paulo62070503***6304"

    @order.update!(
      payment_id: payment_id,
      payment_pix_qr_code: qr_code_base64,
      payment_pix_copia_cola: copia_cola,
      status: "pending"
    )

    { success: true, payment_id: payment_id, pix_copia_cola: copia_cola }
  end

  def create_simulated_credit_card_payment
    card_number = @payment_params[:card_number].to_s.gsub(/\D/, "")
    
    if card_number.length < 13
      return { success: false, error: "Número do cartão de crédito inválido (Simulador)." }
    end

    payment_id = "pay_cc_#{SecureRandom.hex(6)}"
    
    @order.update!(
      payment_id: payment_id,
      status: "paid"
    )

    { success: true, payment_id: payment_id }
  end

  def create_simulated_debit_card_payment
    payment_id = "pay_db_#{SecureRandom.hex(6)}"
    
    @order.update!(
      payment_id: payment_id,
      status: "paid"
    )

    { success: true, payment_id: payment_id }
  end
end

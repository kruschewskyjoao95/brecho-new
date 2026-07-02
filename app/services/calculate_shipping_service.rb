require "net/http"
require "uri"
require "json"

class CalculateShippingService
  DEFAULT_ORIGIN_CEP = "04571010" # CEP da Avenida Berrini, SP (Dona Amélia)

  def initialize(destination_cep:, origin_cep: nil)
    @destination = destination_cep.to_s.gsub(/\D/, "")
    @origin = (origin_cep.presence || DEFAULT_ORIGIN_CEP).to_s.gsub(/\D/, "")
  end

  def call
    return [] unless valid_cep?

    token = Rails.application.credentials.melhor_envio_token || ENV["MELHOR_ENVIO_TOKEN"]
    
    if token.present?
      fetch_real_rates(token)
    else
      calculate_simulated_rates
    end
  rescue => e
    Rails.logger.error "Erro no cálculo de frete real (Melhor Envio): #{e.message}. Usando simulador."
    calculate_simulated_rates
  end

  private

  def valid_cep?
    @destination.length == 8 && @origin.length == 8
  end

  def fetch_real_rates(token)
    # Define URL (Sandbox se em desenv/teste, senão produção)
    env = Rails.env.production? ? "www" : "sandbox"
    uri = URI("https://#{env}.melhorenvio.com.br/api/v2/me/shipment/calculate")

    req = Net::HTTP::Post.new(uri)
    req["Accept"] = "application/json"
    req["Content-Type"] = "application/json"
    req["Authorization"] = "Bearer #{token}"
    req["User-Agent"] = "BrechoRubyApp/1.0"

    # Corpo da requisição com pacote de roupa padrão
    req.body = {
      from: { postal_code: @origin },
      to: { postal_code: @destination },
      packages: [
        {
          width: 20,
          height: 10,
          length: 25,
          weight: 0.5
        }
      ]
    }.to_json

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 8

    res = http.request(req)

    if res.code == "200"
      parse_shipping_options(JSON.parse(res.body))
    else
      Rails.logger.warn "Melhor Envio retornou código #{res.code}: #{res.body}. Usando simulador."
      calculate_simulated_rates
    end
  end

  def parse_shipping_options(results)
    results.map do |option|
      next if option["error"].present?
      
      # Filtramos apenas Correios (PAC e SEDEX) por padrão para o Bazar
      company_name = option.dig("company", "name").to_s.downcase
      next unless company_name.include?("correios")

      {
        id: option["id"].to_s,
        name: "#{option['name']} (Correios)",
        price: option["price"].to_f,
        days: option["delivery_time"].to_i
      }
    end.compact
  end

  def calculate_simulated_rates
    # Determina a taxa base com base na região do CEP
    base_price = case @destination.to_i
                 when 1000000..9999999     # São Paulo Capital
                   12.00
                 when 10000000..19999999   # São Paulo Estado
                   18.50
                 when 20000000..28999999   # Rio de Janeiro
                   22.00
                 when 30000000..39999999   # Minas Gerais
                   24.00
                 when 80000000..99999999   # Região Sul
                   26.50
                 else                      # Outros estados
                   35.00
                 end

    [
      {
        id: 'melhor_envio_pac',
        name: 'PAC (Correios via Melhor Envio - Simulado)',
        price: base_price,
        days: base_price < 20 ? 3 : 7
      },
      {
        id: 'melhor_envio_sedex',
        name: 'SEDEX (Correios via Melhor Envio - Simulado)',
        price: base_price * 1.6,
        days: base_price < 20 ? 1 : 3
      }
    ]
  end
end

class Rack::Attack
  # Limita todos os requests para 100 requests por minuto por IP (Anti-Spam/DDoS)
  throttle('req/ip', limit: 100, period: 1.minute) do |req|
    req.ip unless req.path.start_with?('/assets') || req.path.start_with?('/rails/active_storage')
  end

  # Limita tentativas de login (Brute Force)
  # Permite 5 tentativas de login por IP a cada 1 minuto
  throttle('logins/ip', limit: 5, period: 1.minute) do |req|
    if req.path == '/session' && req.post?
      req.ip
    end
  end

  # Limita tentativas de login por email (Proteção contra brute force focado em uma conta)
  # Permite 5 tentativas por email a cada 1 minuto
  throttle('logins/email', limit: 5, period: 1.minute) do |req|
    if req.path == '/session' && req.post?
      req.params['email_address'].to_s.downcase.gsub(/\s+/, "") if req.params['email_address'].present?
    end
  end

  # Limita criação de favoritos, ofertas, avaliações, perguntas e carrinho (Spam Protection)
  throttle('writes/ip', limit: 20, period: 1.minute) do |req|
    if req.post? && req.path.match?(/\/(favorites|offers|reviews|questions|cart_items)/)
      req.ip
    end
  end
end

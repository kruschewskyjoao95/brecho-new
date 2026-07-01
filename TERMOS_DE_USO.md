# 📜 Termos de Uso e Política de Privacidade — Brechó Ruby

Este documento estabelece as regras, obrigações e políticas de privacidade para todos os usuários (compradores e vendedores) que utilizam a plataforma **Brechó Ruby**. Ao se cadastrar e utilizar nossos serviços, você concorda integralmente com as condições descritas abaixo.

---

## Part I: Termos de Uso (Contrato do Usuário)

### 1. Natureza do Serviço ( Marketplace / Intermediação )
* O **Brechó Ruby** funciona única e exclusivamente como uma plataforma de intermediação e facilitação de negócios (marketplace) de peças de moda novas, seminovas e *vintage*.
* **Isenção de Responsabilidade:** O Brechó Ruby **não é proprietário** das peças anunciadas pelos vendedores, não realiza curadoria física prévia de cada item enviado, e não tem controle sobre a entrega final, qualidade, autenticidade, segurança ou legalidade das peças descritas. Cada vendedor é o único e exclusivo responsável civil e penal por seus respectivos anúncios.

### 2. Regras para Vendedores
* **Descrição Honesta:** O vendedor compromete-se a descrever com precisão o estado de conservação da peça (Novo com etiqueta, Gentilmente usado ou Vintage), apontando eventuais avarias (furos, manchas, rasgos).
* **Autenticidade:** É terminantemente proibida a venda de réplicas, falsificações ou produtos de origem ilícita.
* **Envio:** O vendedor deve despachar o produto dentro do prazo acordado após a confirmação do pagamento. O valor da venda só será liberado ao vendedor após o comprador confirmar o recebimento seguro da peça.
* **Limites de Anúncios:** Cada vendedor tem direito a **2 anúncios gratuitos por mês**. Anúncios adicionais no mesmo período exigem o pagamento de uma taxa de conveniência de **R$ 5,99 por anúncio extra** (limite de 5 fotos por anúncio). Esta taxa não é reembolsável após o anúncio ser criado e veiculado.

### 3. Regras para Compradores
* **Direito de Arrependimento:** Em conformidade com o Artigo 49 do Código de Defesa do Consumidor (CDC) brasileiro, compras online contam com um prazo de arrependimento de **até 7 (sete) dias corridos** a contar do recebimento do produto. Para solicitar a devolução e reembolso, a peça deve estar nas exatas condições em que foi entregue.
* **Pagamento Seguro:** Todas as transações financeiras devem ser realizadas exclusivamente pelos meios oferecidos dentro da plataforma. O Brechó Ruby não se responsabiliza por acordos ou transações financeiras paralelas feitas por fora do sistema.

### 4. Limitação de Responsabilidade Financeira e Danos
* O Brechó Ruby não será responsável por lucros cessantes, danos morais, perda de dados ou danos indiretos decorrentes do uso da plataforma, falhas temporárias do sistema ou atrasos na logística terceirizada (Correios/Transportadoras).

---

## Part II: Política de Privacidade (LGPD)

Em conformidade com a Lei Geral de Proteção de Dados (LGPD - Lei nº 13.709/18), detalhamos abaixo como tratamos e protegemos seus dados pessoais.

### 1. Quais dados coletamos?
* **Dados cadastrais:** Nome completo, endereço de e-mail, telefone, CEP e endereço completo para entrega de mercadorias.
* **Dados financeiros de recebimento:** Chave PIX (CPF, celular, e-mail ou aleatória) informada para resgate de saldos por vendedores.
* **Dados de navegação:** Cookies de sessão e endereço IP para fins de segurança (antifraude e limitação de ataques de força bruta).

### 2. Segurança e Criptografia dos Dados
Adotamos medidas rígidas de segurança técnica:
* **Dados de Cartão de Crédito:** Os dados do seu cartão de crédito **nunca são salvos** ou sequer passam em texto limpo pelo nosso servidor. Eles são criptografados na origem (navegador) e tokenizados diretamente pelo gateway de pagamentos parceiro.
* **Dados Sensíveis (Chaves PIX):** Suas chaves PIX são salvas no banco de dados com **criptografia nativa de nível industrial (AES-256)** através do `ActiveRecord::Encryption` do Rails. Mesmo se houver uma invasão física ao banco de dados, os dados estarão completamente ilegíveis.
* **Proteção de Sessão:** O controle de login utiliza cookies blindados com as tags de proteção `HttpOnly` e `Secure`, impossibilitando que scripts maliciosos capturem sua senha ou sessão ativa.

### 3. Direitos do Usuário (LGPD)
Você tem o direito de, a qualquer momento, entrar em contato com o suporte da plataforma para:
* Confirmar a existência do tratamento de seus dados.
* Solicitar a correção de dados incompletos ou desatualizados.
* **Direito ao Esquecimento:** Solicitar a **exclusão definitiva** dos seus dados pessoais e de sua conta (exceto dados que o Brechó Ruby é legalmente obrigado a manter para cumprimento de obrigações fiscais ou ordens judiciais).

---

## Contato e Suporte
Para reportar abusos, acionar o direito de arrependimento ou solicitar a exclusão de dados pessoais sob a LGPD, entre em contato através do e-mail oficial de suporte: `suporte@brechoruby.com.br`.

*Última atualização: 30 de Junho de 2026.*

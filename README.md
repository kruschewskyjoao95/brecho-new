# 🛍️ Brechó Ruby

O **Brechó Ruby** é uma plataforma de e-commerce e marketplace completa e escalável voltada para compra e venda de peças de vestuário novas e *vintage*. Construído com Ruby on Rails 8, o sistema oferece uma experiência imersiva e reativa sem a complexidade de um SPA (Single Page Application), mantendo a segurança em nível corporativo.

## 🚀 Principais Funcionalidades

* **Multi-Papel (Buyers & Sellers):** Usuários podem se cadastrar como compradores ou vendedores.
* **Catálogo e Filtros Hotwire:** Navegação instantânea e filtros rápidos pelo catálogo via Turbo Frames sem recarregar a página.
* **Carrinho e Checkout Completo:** Fluxo de compra com cálculo de frete em tempo real (com sistema de contingência/fallback caso a API de frete caia).
* **Limites e Monetização de Anúncios:** 
  * Vendedores podem publicar **até 2 anúncios gratuitos por mês**.
  * Peças limitadas a **5 fotos** por anúncio para otimização de armazenamento.
  * Módulo de cobrança (R$ 5,99) para publicação de **anúncios extras**.
* **Gestão Financeira:** Controle de saldo bloqueado/disponível e saques para contas bancárias via PIX.

## 🛡️ Arquitetura e Segurança de Nível Bancário (Bank-Grade Security)

O código foi minuciosamente auditado e blindado contra os maiores vetores de ataque modernos:

* **Proteção PCI-DSS:** Os dados de Cartão de Crédito nunca tocam o backend em texto pleno. A tokenização é realizada 100% via Javascript (*Client-side tokenization*).
* **Criptografia de Banco de Dados:** Chaves PIX e Dados Sensíveis Pessoais (PII) são criptografadas diretamente no banco via `ActiveRecord::Encryption`.
* **Sessões Anti-XSS (Zero Trust):** Substituição de JWTs inseguros no `localStorage` pelo padrão Ouro de Web Security: **Cookies Assinados, `HttpOnly` e `Secure`**.
* **Lock Pessimista (Race Conditions):** O motor financeiro de saques utiliza `Pessimistic Locking` (travamento de linhas no banco) garantindo integridade e prevenindo ataques de fraude de duplo saque (*Double Spending*).
* **Defesa de Borda:** Implementação do `Rack::Attack` para bloquear varreduras de DDoS e força bruta (limite de tentativas de login por IP e E-mail).
* **Prevenção de Escalonamento de Privilégios:** *Strong Parameters* configurados e lógica severa de sobrescrita (Ninguém consegue forjar uma conta `admin` via form-hacking).

## 🛠️ Tecnologias Utilizadas

* **Ruby on Rails 8.1**
* **Banco de Dados:** SQLite3 (Otimizado para WAL-mode de alta performance)
* **Frontend Reativo:** Hotwire (Turbo + Stimulus JS)
* **Estilização:** CSS Moderno e Responsivo
* **Processamento:** Active Job e Solid Queue (Background Jobs)
* **Uploads:** Active Storage
* **Deployment Prontos:** Preparado para orquestração em Docker via `Kamal`.

---

## 💻 Como Rodar o Projeto Localmente

### Pré-requisitos
* **Ruby** instalado na máquina.
* Gerenciador de dependências **Bundler**.

### Passo a passo

1. **Clone o repositório:**
   ```bash
   git clone https://github.com/SEU-USUARIO/brecho-new.git
   cd brecho-new
   ```

2. **Configure as Variáveis de Ambiente:**
   Existe um arquivo modelo que impede que chaves privadas subam para o repositório. Faça uma cópia dele para sua máquina local:
   ```bash
   cp .env.example .env
   ```
   *(Opcional: Abra o arquivo `.env` para inserir suas chaves da API do gateway de pagamento, se for usar o ambiente de testes Sandbox).*

3. **Instale as dependências:**
   ```bash
   bundle install
   ```

4. **Prepare o Banco de Dados:**
   Isso vai criar as tabelas SQLite e as chaves de criptografia necessárias.
   ```bash
   bin/rails db:prepare
   ```

5. **Inicie o Servidor:**
   ```bash
   bin/dev
   ```
   *O projeto estará rodando no seu navegador na porta `http://localhost:3000`.*

## 🧪 Contribuindo

Caso queira contribuir, criar um *fork* ou enviar Pull Requests, certifique-se de não subir modificações para o arquivo `config/credentials.yml.enc` ou arquivos locais como `.env` e bancos de dados SQLite da pasta `storage/`.

Desenvolvido com 💎 para a comunidade Ruby.

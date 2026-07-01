# Revisão Completa de Arquitetura e Segurança - Brechó Ruby

Este documento apresenta uma auditoria completa de segurança, arquitetura e fluxo de dados do projeto de marketplace **Brechó Ruby**. A plataforma lida com dados sensíveis de milhares de potenciais compradores e vendedores, portanto, aplicar metodologias rigorosas de segurança financeira e proteção de dados é fundamental.

---

## 🚨 Pontos Fracos, Vulnerabilidades Críticas e Vazamentos (Weaknesses)

Abaixo estão os pontos de maior risco de segurança identificados na implementação atual do código, seguidos da forma recomendada de correção.

### 1. Insecure Direct Object Reference (IDOR) no Acesso a Pedidos (Vazamento de Dados)
**Onde ocorre:** `OrdersController#show` e `OrdersController#confirm_delivery`.
**O problema:** O método `show` recupera um pedido usando a chave primária incremental simples: `@order = Order.find(params[:id])`. Como o controlador possui a macro `allow_unauthenticated_access` e a ação não checa se o `current_user` é o dono do pedido, **qualquer pessoa ou bot** que iterar números na URL (ex: `/orders/1`, `/orders/2`, `/orders/3`...) pode visualizar o recibo, contendo o nome completo do comprador, valor gasto e todo o seu **Endereço de Entrega** (vazamento grave segundo a LGPD).
**Como corrigir:**
* Para compradores logados: `@order = current_user.orders.find(params[:id])`.
* Para checkout de convidados (anônimos): Use um token público não previsível gerado dinamicamente (UUID) no banco de dados para acessar a rota (ex: `Order.find_by(token: params[:token])`), em vez de expor o ID incremental do banco.

### 2. Quebra de Conformidade PCI-DSS (Vazamento de Cartão de Crédito)
**Onde ocorre:** `OrdersController#create` e `AsaasPaymentService`.
**O problema:** Quando o cliente finaliza o pagamento via Cartão, as variáveis com dados em texto pleno (`:card_number`, `:card_name`, `:card_expiry`, `:card_cvv`) estão sendo submetidas no formulário, caindo diretamente nos parâmetros do servidor Rails (`params.slice(...)`). Um servidor Backend próprio **jamais deve ter contato com dados puros de cartão de crédito** sob as regras de PCI-DSS. Se houver log de requisições, esses números ficarão armazenados de forma não criptografada nos logs do servidor.
**Como corrigir:** Integrar a biblioteca front-end do Gateway (ex: `Asaas.js` ou SDK equivalente) e tokenizar o cartão no navegador do cliente de forma invisível. O servidor Rails deverá receber apenas um *Token Temporário Encriptado* (`payment_token`) e encaminhar esse token para processar a cobrança.

### 3. Falha de Concorrência: Race Condition (Double Spend) no Resgate de Saldo
**Onde ocorre:** `Admin::PayoutsController#create`.
**O problema:** A verificação `if @payout.amount > @user.saldo_disponivel` não é bloqueante no banco de dados. Um vendedor mal-intencionado com saldo de R$ 100 pode disparar um *script automatizado* com 10 requisições simultâneas para resgatar R$ 100. Como a transação não está controlada por locks, todas as 10 requisições vão bater no controlador no mesmo milissegundo, calcular o limite como "OK" (antes da primeira dar update) e salvar 10 saques, resgatando R$ 1000 reais.
**Como corrigir:** Isolar o bloco dentro de uma transação de banco com `Pessimistic Locking`. Você pode utilizar `@user.lock!.saldo_disponivel` ou adotar o padrão arquitetural "Ledger", onde saldos não são recalculados dinamicamente via Ruby a todo instante, mas debitados serialmente com proteção `ActiveRecord Transaction`.

### 4. Armazenamento Desprotegido de Chaves Pix e Dados Financeiros
**Onde ocorre:** Modelo `Payout` (`pix_key`) e campos do `User`.
**O problema:** Chaves PIX muitas vezes equivalem ao número do CPF ou número de celular pessoal do usuário. Estas estão salvas em texto puro nas colunas do banco de dados (sem criptografia no nível da camada do framework).
**Como corrigir:** O Rails v7/v8 oferece a API de `ActiveRecord::Encryption`. Basta adicionar `encrypts :pix_key, deterministic: true` no modelo `Payout` para que, mesmo em caso de dump do banco de dados por SQL Injection ou vazamento físico, essas chaves permaneçam ilegíveis para o atacante.

---

## ✅ Pontos Fortes, Proteções Nativas e Arquitetura Positiva

Felizmente, as fundações do projeto e tecnologias modernas escolhidas provêm um altíssimo padrão contra vetores clássicos de ataque:

### 1. Ausência de JWT Frontend e Prevenção Contra Roubos via XSS (Zero Trust Client)
Muitos sistemas cometem o erro de desacoplar um frontend React usando tokens JWT (JSON Web Tokens) e armazená-los no `LocalStorage`. Este projeto utiliza a solução monolítica baseada no `ActionDispatch::Session::CookieStore` padrão do Rails. 
* **O Vantagem:** Todos os identificadores de login (`session_token`) são cookies assinados criptograficamente de maneira inviolável, e circulam apenas via cabeçalhos marcados automaticamente com as bandeiras **`HttpOnly`** e **`Secure`**. Isso torna **matematicamente impossível** para scripts maliciosos (XSS injetado em campos descritivos) ou extensões do Chrome roubarem a sessão dos usuários (fato corriqueiro em sistemas com JWT não administrado via cookie HTTPOnly).

### 2. Integração Resiliente e Proteção Contra Interrupções Terceirizadas (Design Pattern)
Serviços essenciais, como `TrackShipmentService` e `AsaasPaymentService`, foram arquitetados isolando dependências externas.
* **O Vantagem:** A presença de blocos `.rescue` proativos com algoritmos e calculadoras simuladas como **Fallback (Degradação Graciosa)** garantem que, em caso de instabilidade na API dos Correios, Melhor Envio, ou falhas no Gateway, o e-commerce continua finalizando compras. Essa alta tolerância a falhas aumenta enormemente a receita ao reduzir a perda de carrinhos abandonados por *Timeouts*.

### 3. Proteção Automática Contra Injection e CSRF
* **SQL Injection**: Utilização estrita das interfaces de pesquisa seguras do ActiveRecord com interpolação vinculada (`?`) para filtros dinâmicos na busca em vez de strings concatenadas de SQL puro.
* **Cross-Site Request Forgery (CSRF)**: Através das proteções padrão da base do ActionController, os formulários injetam invisivelmente os *authenticity tokens*. Requisições de forjamento externo visando prejudicar contas de lojistas logados são rejeitadas de imediato no nível do Middleware, garantindo blindagem aos endpoints financeiros.

### 4. Performance e UX Protegida (Turbo e Hotwire)
Ao não expor endpoints via APIs JSON RESTful abertas (e substituí-las pela renderização fluida no lado do servidor via `Turbo Frames` e `Turbo Streams`), o backend não entrega metadados não intencionais da estrutura do sistema. O estado total é preservado em memória blindada pelo Rails, tornando a exploração por varreduras cibernéticas drasticamente mais complexa, enquanto a interatividade fica comparável a SPAs robustos.

---

## 🎯 Conclusão e Recomendações de Evolução 

O projeto Brechó Ruby é uma base extremamente promissora e performática! As integrações entre Hotwire e a navegação do catálogo (filtros em tempo real) entregam um aspecto luxuoso e requintado que reflete positivamente a credibilidade para compradores.

**Para tornar esta plataforma 100% à prova de balas ("Bank-Grade Security"):**
1. Adicione os **Filtros de Bloqueio (IDOR)** garantindo que um ID não permita o acesso livre na visualização de relatórios do usuário anonimamente.
2. Migre o preenchimento de **Dados do Cartão de Crédito** para componentes isolados (Iframes/SDKs de Frontend) exigidos por normativas PCI.
3. Adicione o **`encrypts` do Rails** para chaves PIX.
4. (Opcional, porém recomendado) Introduza a rotina de validação para receber **Webhooks Assinados**, conferindo chaves criptografadas SHA256 vindas do Asaas no endpoint de retorno para garantir que um atacante não falsifique relatórios de aprovação de pagamentos.

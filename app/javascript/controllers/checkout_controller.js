import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "cep", "shippingContainer", "creditCardFields", "totalDisplay", "shippingDisplay", "street", "neighborhood", "city", "state", "paymentToken", "cardNumber", "cardName", "cardExpiry", "cardCvv" ]

  connect() {
    this.calculateShipping()
  }

  calculateShipping() {
    const cep = this.cepTarget.value.replace(/\D/g, "")
    if (cep.length === 8) {
      // 1. Consulta ViaCEP para autopreencher endereço
      fetch(`https://viacep.com.br/ws/${cep}/json/`)
        .then(response => response.json())
        .then(data => {
          if (!data.erro) {
            if (this.hasStreetTarget) this.streetTarget.value = data.logradouro
            if (this.hasNeighborhoodTarget) this.neighborhoodTarget.value = data.bairro
            if (this.hasCityTarget) this.cityTarget.value = data.localidade
            if (this.hasStateTarget) this.stateTarget.value = data.uf
          }
        })
        .catch(err => console.error("Erro ao buscar CEP no ViaCEP:", err))

      // 2. Envia requisição para calcular o frete no Rails
      const formData = new FormData()
      formData.append("cep", cep)
      
      fetch("/orders/calculate_shipping", {
        method: "POST",
        headers: {
          "X-CSRF-Token": document.querySelector("[name='csrf-token']").content,
          "Accept": "text/html"
        },
        body: formData
      })
      .then(response => response.text())
      .then(html => {
        this.shippingContainerTarget.innerHTML = html
        this.updateTotal()
      })
    }
  }

  togglePaymentFields(event) {
    const selectedMethod = event.target.value
    if (selectedMethod === "credit_card") {
      this.creditCardFieldsTarget.style.display = "block"
    } else {
      this.creditCardFieldsTarget.style.display = "none"
    }
  }

  updateTotal() {
    const selectedOption = this.shippingContainerTarget.querySelector("input[name='shipping_option']:checked")
    if (selectedOption) {
      const price = parseFloat(selectedOption.dataset.price)
      const subtotal = parseFloat(this.totalDisplayTarget.dataset.subtotal)
      
      this.shippingDisplayTarget.textContent = `R$ ${price.toFixed(2)}`
      
      const total = subtotal + price
      this.totalDisplayTarget.textContent = `R$ ${total.toFixed(2)}`
      
      document.getElementById("hidden_shipping_cost").value = price
      document.getElementById("hidden_shipping_method").value = selectedOption.dataset.name
    }
  }

  processPayment(event) {
    const methodInput = document.querySelector("input[name='order[payment_method]']:checked")
    if (methodInput && methodInput.value === "credit_card") {
      event.preventDefault()
      
      // Tokenização de segurança PCI-DSS no lado do cliente
      const cardNumber = this.cardNumberTarget.value.replace(/\D/g, "")
      
      if (cardNumber.length < 13) {
        alert("Número de cartão de crédito inválido.")
        return
      }

      // Simula uma chamada assíncrona ao gateway (Asaas.js / Stripe)
      setTimeout(() => {
        const token = "tok_" + btoa(cardNumber).substring(0, 16)
        this.paymentTokenTarget.value = token
        
        // Limpa os dados em texto plano para garantir que não serão submetidos
        this.cardNumberTarget.value = ""
        this.cardNameTarget.value = ""
        this.cardExpiryTarget.value = ""
        this.cardCvvTarget.value = ""
        
        event.target.submit()
      }, 500)
    }
  }
}

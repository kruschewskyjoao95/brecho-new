require "open-uri"

puts "Limpando banco de dados..."
OrderItem.destroy_all
Order.destroy_all
CartItem.destroy_all
Cart.destroy_all
Product.destroy_all
User.destroy_all

puts "Criando usuário administrador..."
admin = User.create!(
  name: "Dona Amélia (Admin)",
  email_address: "contato@amelialookbook.com.br",
  password: "password123",
  role: "admin",
  cep: "04571-010",
  address_street: "Avenida Engenheiro Luís Carlos Berrini",
  address_number: "1000",
  address_neighborhood: "Cidade Monções",
  address_city: "São Paulo",
  address_state: "SP"
)

puts "Criando usuário vendedor de teste..."
seller = User.create!(
  name: "Clara Vendedora",
  email_address: "clara@brechoruby.com.br",
  password: "password123",
  role: "seller",
  cep: "01001-000",
  address_street: "Praça da Sé",
  address_number: "123",
  address_neighborhood: "Centro",
  address_city: "São Paulo",
  address_state: "SP"
)

puts "Criando produtos femininos (Catálogo)..."

products_data = [
  {
    name: "Vestido Midi Amalie",
    description: "Vestido midi em linho puro, cor crua, caimento solto com cinto faixa. Perfeito para passeios e ocasiões especiais de dia. Lavar à mão.",
    price: 189.90,
    price_promo: 170.91, # 10% de desconto no Pix/à vista
    category: "Vestidos",
    sizes: "P, M, G",
    colors: "Cru, Bege",
    stock: 5,
    image_url: "https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=800&auto=format&fit=crop"
  },
  {
    name: "Blusa Aurora em Crepe",
    description: "Blusa manga curta bufante em crepe acetinado. Modelagem soltinha e gola média. Super elegante para o trabalho ou look casual-chic.",
    price: 89.90,
    price_promo: 80.91,
    category: "Blusas",
    sizes: "PP, P, M, G",
    colors: "Branco, Rosa Seco",
    stock: 12,
    image_url: "https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=800&auto=format&fit=crop"
  },
  {
    name: "Calça Alfaiataria Florença",
    description: "Calça pantalona alfaiataria cintura alta, tecido encorpado que não amassa fácil. Possui bolsos frontais e passador de cinto largo.",
    price: 149.90,
    price_promo: 134.91,
    category: "Calças",
    sizes: "P, M, G, GG",
    colors: "Preto, Terracota",
    stock: 8,
    image_url: "https://images.unsplash.com/photo-1541099649105-f69ad21f3246?w=800&auto=format&fit=crop"
  },
  {
    name: "Blazer Oversized L'Amour",
    description: "Blazer alfaiataria oversized com forro de cetim. Estrutura leve nos ombros para um caimento impecável. Combine com jeans ou alfaiataria.",
    price: 259.90,
    price_promo: 233.91,
    category: "Conjuntos",
    sizes: "P, M, G",
    colors: "Fend, Preto",
    stock: 4,
    image_url: "https://images.unsplash.com/photo-1591047139829-d91aecb6caea?w=800&auto=format&fit=crop"
  },
  {
    name: "Cropped Renda Helena",
    description: "Cropped em renda guipir com forro de algodão na frente. Alças finas reguláveis. Peça romântica e delicada para montar sobreposições.",
    price: 79.90,
    price_promo: 71.91,
    category: "Blusas",
    sizes: "P, M",
    colors: "Off-White, Preto",
    stock: 10,
    image_url: "https://images.unsplash.com/photo-1509631179647-0177331693ae?w=800&auto=format&fit=crop"
  },
  {
    name: "Saia Midi Plissada Clara",
    description: "Saia midi plissada em crepe leve com cós elástico confortável. Movimento fluido e romântico. Combine com rasteiras ou salto.",
    price: 119.90,
    price_promo: 107.91,
    category: "Saias",
    sizes: "M, G",
    colors: "Rosa Pastel, Azul Marinho",
    stock: 7,
    image_url: "https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?w=800&auto=format&fit=crop"
  },
  {
    name: "Macacão Pantalona Celine",
    description: "Macacão longo pantalona com decote transpassado e amarração regulável na cintura. Tecido viscolinho super fresco e de caimento leve.",
    price: 219.90,
    price_promo: 197.91,
    category: "Conjuntos",
    sizes: "P, M, G",
    colors: "Verde Oliva, Preto",
    stock: 3,
    image_url: "https://images.unsplash.com/photo-1496747611176-843222e1e57c?w=800&auto=format&fit=crop"
  },
  {
    name: "Kimono Estampado Verano",
    description: "Kimono longo estampado floral em viscose premium. Abertura ampla nas mangas. Perfeito como terceira peça ou saída de praia charmosa.",
    price: 99.90,
    price_promo: 89.91,
    category: "Moda Praia",
    sizes: "Único",
    colors: "Estampa Floral",
    stock: 15,
    image_url: "https://images.unsplash.com/photo-1539109136881-3be0616acf4b?w=800&auto=format&fit=crop"
  },
  {
    name: "Tricot Leve Soft",
    description: "Blusa de tricot de gramatura leve com gola em V. Toque super macio na pele, ideal para dias frescos de outono ou primavera.",
    price: 129.90,
    price_promo: 116.91,
    category: "Blusas",
    sizes: "P, M, G",
    colors: "Bege, Cinza Mescla",
    stock: 6,
    image_url: "https://images.unsplash.com/photo-1574169208507-84376144848b?w=800&auto=format&fit=crop"
  },
  {
    name: "Jaqueta Jeans Oversized",
    description: "Jaqueta jeans com lavagem média estonada e modelagem oversized. Bolsos frontais e fechamento em botões de metal personalizados.",
    price: 179.90,
    price_promo: 161.91,
    category: "Casacos",
    sizes: "P, M, G, GG",
    colors: "Jeans Azul",
    stock: 5,
    image_url: "https://images.unsplash.com/photo-1576995853123-5a10305d93c0?w=800&auto=format&fit=crop"
  },
  {
    name: "Vestido Longo Boho Chic",
    description: "Vestido longo estilo boho com detalhes em lastex no busto e mangas ciganinhas. Tecido viscose leve estampada. Caimento rodado lindo.",
    price: 249.90,
    price_promo: 224.91,
    category: "Vestidos",
    sizes: "P, M, G",
    colors: "Azul Estampado",
    stock: 4,
    image_url: "https://images.unsplash.com/photo-1572804013309-59a88b7e92f1?w=800&auto=format&fit=crop"
  },
  {
    name: "Biquíni Ripple Maresias",
    description: "Conjunto de biquíni ripple (efeito empina bumbum) com amarração lateral no quadril. Bojo removível e tecido com proteção UV50+.",
    price: 139.90,
    price_promo: 125.91,
    category: "Moda Praia",
    sizes: "P, M, G",
    colors: "Verde Esmeralda",
    stock: 8,
    image_url: "https://images.unsplash.com/photo-1612336307429-8a898d10e223?w=800&auto=format&fit=crop"
  }
]

products_data.each_with_index do |data, index|
  img_url = data.delete(:image_url)
  p = Product.new(data)
  p.seller = index.even? ? seller : admin
  
  if p.save
    puts "Criado: #{p.name}"
    begin
      # Baixa imagem da internet e anexa via Active Storage
      file = URI.open(img_url, read_timeout: 10)
      filename = "#{p.name.parameterize}.jpg"
      p.images.attach(io: file, filename: filename, content_type: "image/jpeg")
      puts "  -> Imagem anexada."
    rescue => e
      puts "  -> Falha ao baixar imagem: #{e.message}. Criado sem imagem."
    end
  else
    puts "Erro ao criar #{data[:name]}: #{p.errors.full_messages.join(', ')}"
  end
end

puts "\nSeeding concluído! #{Product.count} produtos criados."


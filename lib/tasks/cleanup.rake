namespace :cleanup do
  desc "Limpa carrinhos vazios e antigos do banco de dados (mais de 7 dias)"
  task carts: :environment do
    puts "Iniciando limpeza de carrinhos antigos..."
    
    # Carrinhos criados há mais de 7 dias que não possuem itens
    empty_carts = Cart.where("created_at < ?", 7.days.ago).left_outer_joins(:cart_items).where(cart_items: { id: nil })
    count = empty_carts.count
    
    empty_carts.destroy_all
    
    puts "Limpeza concluída! #{count} carrinhos vazios removidos."
  end
end

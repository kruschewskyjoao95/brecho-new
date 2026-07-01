xml.instruct! :xml, version: '1.0', encoding: 'UTF-8'
xml.urlset xmlns: 'http://www.sitemaps.org/schemas/sitemap/0.9' do
  # Home
  xml.url do
    xml.loc root_url
    xml.lastmod Time.current.to_date.to_s
    xml.changefreq 'daily'
    xml.priority '1.0'
  end

  # Products
  @products.each do |product|
    xml.url do
      xml.loc product_url(product)
      xml.lastmod product.updated_at.to_date.to_s
      xml.changefreq 'weekly'
      xml.priority '0.8'
    end
  end
end

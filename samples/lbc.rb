require_relative '../boot'

URL = 'http://www.leboncoin.fr/ventes_immobilieres'

yo = Scarabee.scraper do |url|
  open url
  
  pick 'div.header_adview > h1', as: :title, format: :text
  pick 'span.price', as: :price, format: :price
  pick 'td[itemprop="addressLocality"]', as: :city, format: :text
  pick 'td[itemprop="postalCode"]', as: :zipcode, format: :text
  pick 'span.urgent', as: :urgent, format: :text
  pick_table 'div.criterias > table', as: :criteres, key: 'th', value: './/td/*[not(self::script)]|.//td/text()'
end

Scarabee.scraper do |url|
  open url
  get 'div.list-lbc > a', as: :urls, format: :href
  get '//li[@class="page"][last()]/a[1]', as: :next_page, format: :href, array: false
  crawl :urls, with: yo
  next_page :next_page, stop: 3 do |entries|
    #Store in database
    p entries
  end
end.run(url: URL)
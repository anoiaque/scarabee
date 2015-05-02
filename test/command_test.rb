require 'test_helper'

class Scarabee::CommandTest < Minitest::Test
  URL = 'http://www.leboncoin.fr/ventes_immobilieres'
  
  def setup
  end

  def test_basic_scraper_creation_via_dsl
    yo = Scarabee.scraper do
      open URL
      pick 'div.detail > h2.title', as: :title, format: :text
      pick 'div.detail > div.price', as: :price, format: :price
    end
    
    entries = yo.run
    title = entries[0][:title]
    price = entries[0][:price]
    
    assert entries.count >= 10
    assert title.is_a?(String)
    assert title.length > 5
    assert price.is_a?(Float)
    assert price > 5
  end
  
  def test_get_command_passing_block_to_extract_attribute_value_of_node
    lbc = Scarabee.scraper do
      open URL
      get 'div.list-lbc > a', as: :urls do |node| 
        node.attributes['href'].value 
      end
    end
    
    lbc.run
    urls = lbc.instance_variable_get(:@urls)
    
    assert urls.count > 10
    assert urls[0] =~ /http:\/\/www\.leboncoin\.fr\/ventes_immobilieres\/\d+/
  end
  
  def test_crawl_and_scrape_using_scraper_definition
    yo = Scarabee.scraper do |url|
      open url
      pick 'span.price', as: :price, format: :price
      pick 'td[itemprop="addressLocality"]', as: :city, format: :text
    end
    
    lbc = Scarabee.scraper do
      open URL
      get 'div.list-lbc > a', as: :urls do |node| 
        node.attributes['href'].value 
      end
      crawl :urls, with: yo, only: (2..5)
    end
    
    entries = lbc.run
    assert_equal 4, entries.uniq.count
    assert entries[0][:city]
    assert entries[0][:price]
  end
end
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
  
  def test_crawl_over_pagination_and_scrape_each_page
    yo = Scarabee.scraper do |url|
      open url
      pick 'span.price', as: :price, format: :price
      pick 'td[itemprop="addressLocality"]', as: :city, format: :text
    end
    
    lbc = Scarabee.scraper do |url|
      open url
      get 'div.list-lbc > a', as: :urls, format: :href
      get '//li[@class="page"][last()]/a[1]', as: :next_page, format: :href, array: false
      crawl :urls, with: yo, only: (0..1)
      next_page :next_page, stop: 3
    end
    entries = lbc.run(url: URL)

    assert_equal 6, entries.uniq.count
    assert_equal 3, lbc.page_count
  end
  
  def test_stop_unless_next_page_url
    lbc = Scarabee.scraper do |url|
      open url
      get '//li[@class="page"][last()]/a[1]', as: :next_page, format: :href, array: false
      next_page :next_page
    end
    
    url = "http://www.leboncoin.fr/ventes_immobilieres/offres/ile_de_france/occasions/?o=34159000"
    lbc.run(url: url)
    
    assert_equal 1, lbc.page_count
  end
  
  def test_return_empty_array_on_failure_in_commands_run
    Scarabee::Formatter.stubs(:[]).raises
    
    lbc = Scarabee.scraper do |url|
      open url
      get '//li[@class="page"][last()]/a[1]', as: :next_page, format: :href, array: false
      next_page :next_page, stop: 3
    end
    
    entries = lbc.run(url: URL)
    e = lbc.errors.first
    
    assert_equal :get, e.method
    assert_equal URL, e.url
    assert e.kind.is_a?(RuntimeError)
  end
end
module Scarabee
  class Exception < ::Exception
    attr_reader :method, :url, :kind
    def initialize method, url, kind
      @method = method
      @url = url
      @kind = kind 
    end
  end
  
  module Formatter
    def [] symbol
      symbol ? send(symbol) : none
    end
    
    def none
      @@none ||= ->(node) { node }
    end
    
    def price
      @@price ||= ->(node) { node.text.match(/\d+[,\.\s]*\d*/)[0].gsub(/\s+/, '').gsub(/,/, '.').to_f  }
    end
    
    def text
      @@text ||= ->(node) { node.text.gsub(/\n|\t/, '').strip.gsub(/\s+/, ' ')  }
    end
    
    def href
      @@href ||= ->(node) { node.attributes['href'].value }
    end
    extend self
  end
  
  class Scraper
    attr_reader :entries, :page_count, :errors
    
    def initialize agent: nil, &commands
      @commands = commands
      @agent = agent
      @entries = []
      @page_count = 1
      @errors = []
    end
    
    def get xpath, as: :ivar, format: nil, array: true
      nodes = @page.search(xpath)
      values = nodes.map { |node| block_given? ? yield(node) : Formatter[format].(node) }
      
      values = values.first unless array
      instance_variable_set "@#{as}", values
      
    rescue => e
      @errors << Scarabee::Exception.new(:get, @page.uri.to_s, e)
    end
    
    def pick xpath, as: :key, format: nil
      nodes = @page.search(xpath)
      
      nodes.each_with_index { |node, index|
        @entries[index] ||= Hash.new
        @entries[index][as] = Formatter[format].(node)
      }
      
    rescue => e
      @errors << Scarabee::Exception.new(:pick, @page.uri.to_s, e)
    end
    
    def open url
      @page = @agent.get url
      
    rescue => e
      @errors << Scarabee::Exception.new(:open, @page.uri.to_s, e)
    end
    
    def crawl urls, with: :scraper, only: (0..-1)
      urls = instance_variable_get "@#{urls}"
      
      urls[only].each { |url| with.run(url: url).each { |e| @entries << e.dup } }
    
    rescue => e
      @errors << Scarabee::Exception.new(:crawl, @page.uri.to_s, e)
    end
    
    def next_page ivar, stop: 0
      return if stop == @page_count
      return unless url = instance_variable_get("@#{ivar}")

      @page_count += 1

      if block_given? #yield entries and clear it to reduce memory usage
        yield @entries
        @entries = []
      end
      
      instance_exec url, &@commands
    end
    
    def run url: nil
      instance_exec url, &@commands
      entries
    end
    
  end
  
  def self.scraper &commands
    Scraper.new(agent: agent, &commands)
  end
  
  def self.agent
    @@agent ||= Mechanize.new
  end
end
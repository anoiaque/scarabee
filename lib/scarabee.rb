module Scarabee
  module Formatter
    def [] symbol
      symbol ? send(symbol) : none
    end
    
    def none
      @@none ||= ->(text) { text }
    end
    
    def price
      @@price ||= ->(text) { text.match(/\d+[,\.\s]*\d*/)[0].gsub(/\s+/, '').gsub(/,/, '.').to_f  }
    end
    
    def text
      @@text ||= ->(text) { text.gsub(/\n|\t/, '').strip.gsub(/\s+/, ' ')  }
    end
    extend self
  end
  
  class Scraper
    attr_reader :agent, :page, :entries
  
    def initialize agent: nil, &commands
      @commands = commands
      @agent = agent
      @entries = []
    end
    
    def get xpath, as: :ivar
      values = @page.search(xpath).map { |node| block_given? ? yield(node) : node }
      
      instance_variable_set "@#{as}", values
    end
    
    def pick xpath, as: :key, format: nil
      @page.search(xpath).each_with_index do |node, index|
        @entries[index] ||= Hash.new
        @entries[index][as] = Formatter[format].(node.text)
      end
    end
    
    def open url
      @page = agent.get url
    end
    
    def crawl urls, with: :scraper, only: (0..-1) 
      urls = instance_variable_get "@#{urls}"
      
      urls[only].each { |url| with.run(url: url).each { |e| @entries << e.dup } }
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
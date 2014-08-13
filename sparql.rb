require 'rest-client'
require 'json'
require 'pry'

class Sparql
  attr_accessor :name
  attr_reader :url, :map, :chain

  def initialize(name)
    raise "name cannot be blank" if name == ""
    @name = name
    @url = "http://opendatacommunities.org/sparql.json"
    @map = {
      #/county/ => "#{prefix}/county",
      #/country/ => "#{prefix}/country",
      /district/i => District,
      /ward/i => Ward
    }

    @map.default_proc = lambda do |hash,lookup|
      hash.each_pair do |key, value|
        return value if key =~ lookup
      end
      return nil
    end

    @chain = []
  end

  def create_elements(data)
    _id = data.map { |el| el["id"]["value"] =~ /data.ordnancesurvey.co.uk/ ? el["id"]["value"] : nil }.compact.first
    _types = data.map { |el| @map[el["type"]["value"]] }.compact
    _types.each do |type|
      element = type.new(_id)
      @chain << element if !@chain.include?(element)
    end
  end

  def run_query
    query = <<-eos
      SELECT ?id ?type 
      WHERE { 
        ?id <http://www.w3.org/2000/01/rdf-schema#label> "#{@name}" . 
          ?id <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> ?type 
      }
      eos

    results_str = RestClient.get url, {:params => {:query => query}}
    results_hash = JSON.parse results_str
    results_array = results_hash["results"]["bindings"]
    create_elements(results_array)
  end
end

class District < Sparql
  attr_accessor :name, :type

  def initialize(name)
    super(name)
    prefix = "http://data.ordnancesurvey.co.uk/ontology/postcode"
    @type = "#{prefix}/district"
  end

  def ==(another)
    @name == another.name && @type == another.type
  end

  def run_query
    query = <<-eos
      SELECT DISTINCT ?id
      WHERE { 
        ?id <#{@type}> <#{@name}>
      }
      eos

    results_str = RestClient.get url, {:params => {:query => query}}
    results_hash = JSON.parse results_str
    results_array = results_hash["results"]["bindings"]
    puts "Sample postcodes: " + results_array.sample(10).map { |el| el["id"]["value"].gsub("http://data.ordnancesurvey.co.uk/id/postcodeunit/","") }.join(", ")
    puts "total number of postcodes: #{results_array.length}"
  end
end

class Ward
  attr_accessor :name, :type

  def initialize(name)
    super(name)
    prefix = "http://data.ordnancesurvey.co.uk/ontology/postcode"
    @type = "#{prefix}/ward"
  end

end

sp = Sparql.new('Croydon')
sp.run_query
sp.chain.each(&:run_query)

sp = Sparql.new('Wakefield')
sp.run_query
sp.chain.each(&:run_query)
#
# Load postcodes
#query = <<-eos
  #SELECT DISTINCT ?id
  #WHERE { 
    #?id <#{type}> <#{id}>
  #}
  #eos

#results_str = RestClient.get url, {:params => {:query => query}}
#results_hash = JSON.parse results_str
#results_array = results_hash["results"]["bindings"]


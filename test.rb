require 'pry'
require 'rdf'
require 'rdf/ntriples'

#RDF::Reader.open("data/administrative-geography.nt") do |reader|
  #reader.each_statement do |statement|
    #puts statement.inspect
    #exit 0
  #end
#end

graph = RDF::Graph.load("data/administrative-geography.nt")
binding.pry

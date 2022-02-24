#!/bin/ruby
require 'levenshtein'

class Chunk
   include Comparable
   attr :str
   def <=>(other)
      0.2 <=> Levenshtein.normalized_distance(str, other.str)
   end
   def initialize(str)
      @str = str
   end
   def inspect
      @str
   end
   def to_s
      @str
   end
end

rawChunks = [
   'ERROR all your base belong to us.',
   "asldkj", 
   'Error in joeMama. Proxy response code: {"message":"Request failed with status code 200","name":"Error",',
   "ofghi", 
   'the quick fox shat deftly onto the old dog.',
   "apple", 
   'VICTORY all you base belong to us.', 
   "1bcdeee", 
   'Error in requestByAsin. Proxy response code: {"message":"Request failed with status code 3","name":"Error",',
   "abcefg", 
   'the quick dog flexed aptly onto the old dog.',
   "mapple"
   'Error in requestByAsin. Proxy response code: {"message":"Request failed with status code 429","name":"Error",',
   "abcdefh", 
];

chunks = rawChunks.map{|s| Chunk.new s }
#chunks = [];


chunks.sort

puts chunks.map{|x| x.inspect }



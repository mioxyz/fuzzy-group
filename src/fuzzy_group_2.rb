#!/bin/ruby
require 'levenshtein'

DATE_PATTERN = /\[ [0-9]{2}\.[0-9]{2}\.20[0-9]{2} [0-9]{2}:[0-9]{2} \]/

class Chunk
   include Comparable
   attr :str
   CUTOFF_VAL = 0.2

   def <=>(other)
      CUTOFF_VAL <=> Levenshtein.normalized_distance(str, other.str)
   end

   def initialize(str)
      @str = str
   end

   def to_s
      @str
   end
end

handle = File.new( ARGV[0], "r")

if not handle then
   puts "ERROR: couldn't open file handle."
   exit true;
end

chunks = handle.sysread(handle.size)
               .split(DATE_PATTERN)
               .shuffle()
               .map{|s| Chunk.new s };
chunks.sort

puts chunks.map{|x| x.to_s }

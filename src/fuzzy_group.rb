#!/bin/ruby
require 'levenshtein'

DATE_PATTERN = /\[ [0-9]{2}\.[0-9]{2}\.20[0-9]{2} [0-9]{2}:[0-9]{2} \]/
CUTOFF_VAL = 0.1

class Group
   attr_accessor :president
   attr_accessor :members
   def initialize(president = "")
      @president = president
      @members = []
   end
end

handle = File.new( ARGV[0], "r")

if not handle then
   puts "ERROR: couldn't open file handle."
   exit true;
end

groups = [ ];

handle.sysread(handle.size()).split(DATE_PATTERN).each do |chunk|
   group = groups.find{ |g| 
      CUTOFF_VAL > Levenshtein.normalized_distance(
         g.president[0..[600, g.president.length].min],
         chunk[0..[600, chunk.length].min]
      )
   }
   if group then
      group.members.push(chunk)
   else
      groups.push(Group.new(chunk))
   end
end

groups.each do |group| 
   puts group.president
   puts '=' * 80
   puts ''
end

puts "Groupcount: "
puts groups.length

# chunks.each_index do |x| 
#    chunks.each_index do |y|
#       next if x == y
#       isMember = false;
#       groups.each do |group| 
#          Levenshtein.normalized_distance(group.president, chunks
#       end # groups
#       puts Levenshtein.normalized_distance(
#          chunks[x][0..[chunks[x].length, 300].min],
#          chunks[y][0..[chunks[y].length, 300].min]
#       );
#    end
# end

#chunks.each do |chunk|
   #isMember = false;
   # groups.each do |group| 
   #    if 0.1 > Levenshtein.normalized_distance(group.president, chunk) then
   #       isMember = true
   #       group.members.push chunk
   #    end
   # end
   # if not isMember then
   #    groups.push Group.new chunk
   # end
#end

# obviously there are weaknesses with this approach. We cannot exclude the possibility
# of groups being too similar to eachother. E.g. If you have strings A,B,C and
# ls(A,B) == 0.03, ls(A,C) == 0.14, ls(B,C) == 0.09
# you can get into situations where "find" will put the member into the less fit group,
# also, the first president might be an outlier in the group. The cutoffvalue of 0.1 c
# casts a ball around which ever element comes first, and anything lying outside of the
# ball will be excluded from the group.


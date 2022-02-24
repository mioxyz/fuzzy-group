#!/bin/ruby
require 'levenshtein'

DATE_PATTERN = /\[ [0-9]{2}\.[0-9]{2}\.20[0-9]{2} [0-9]{2}:[0-9]{2} \]/
CUTOFF_VAL = 0.2

MAX_CHUNK_LEN = 5 * 1000;
MAX_PARTITION_LEN = 20 * 1000;
MAX_THREAD_COUNT = 4;
CHUNK_CUTOFF_LEN = 600; # this is sort of bad and should be removed
MEMBER_COUNT_MIN = 3;


class Group
   attr_accessor :president
   # attr_accessor :members
   attr_accessor :member_count
   attr_accessor :partition_index
   # attr_accessor :usurper

   def initialize(president = "", partition_index = 0, member_count = 0)
      @president = president
      @partition_index = partition_index
      @members = []
      @member_count = member_count;
   end
   # union not that useful now, but when the usurper logic starts to take shape...
   def union(other)
      return Group.new(@president, @partition_index, @member_count + other.member_count)
   end
   def union!(other)
      @member_count += other.member_count
   end
end

def cluster(chunks, partition_index)
   # puts "+++cluster #{partition_index}"
   groups = [ ];
   chunks.each do |chunk|
      group = groups.find{ |g|
         CUTOFF_VAL > Levenshtein.normalized_distance(
            g.president[0..[CHUNK_CUTOFF_LEN, g.president.length].min],
            chunk[0..[CHUNK_CUTOFF_LEN, chunk.length].min]
         )
      }
      if group then
         # group.members.push(chunk)
         group.member_count += 1;
      else
         groups.push(Group.new(chunk, partition_index))
      end
   end
   # puts "+++cluster #{partition_index} returning groups: "
   # groups.each{|x| puts "member_count: #{x.member_count};    #{x.president}"}
   return groups
end

def partitionChunks(chunks)
   partitions = [ [] ]
   accum = 0
   chunks.each do |chunk|
      next if MAX_CHUNK_LEN < chunk.length # skip chunks which are too big
      accum += chunk.length
      partitions.last.push chunk
      if MAX_PARTITION_LEN < accum then
         partitions.push []
         accum = 0
      end
      # puts "accum: #{accum}"
   end
   return partitions
end

handle = File.new( ARGV[0], "r")

if not handle then
   puts "ERROR: couldn't open file handle."
   exit true;
end

chunks = handle.sysread(handle.size()).split(DATE_PATTERN);

partitions = partitionChunks(chunks)

puts "partitions count: #{partitions.count}"

threads = []
threadCount = 0;
partitions.map.with_index do |partition, partition_index|
   next if partition.length == 0

   threads.push Thread.new{
      Thread.current["groups"] = cluster(partition, partition_index)
   }
   ret = cluster(partition, partition_index);
   # puts "test shit"
   # puts ret[0].president;

   threadCount += 1;
   if MAX_THREAD_COUNT < threadCount then
      puts "waiting for threads to complete..."
      puts "partition_index: #{partition_index}"
      threads.each{ |thread| thread.join }
      threadCount = 0
   end
end

threads.each{ |thread| thread.join }

# now we still need to merge the results into one big schlong. The bang ! means that we are doing the operation in place, and not making an extra copy of the whole array. We are going from [[grp1, grp2,..], [grp3,..], ... ] to [grp1, grp2, grp3, ...] using the flatten operation.
# puts "beh?"
# puts "theads.length #{threads.length}"
# sampleGroups = threads[0]["groups"];
#puts sampleGroups[0].president #crazyily this is making problems? It is a race condition!

# puts "======================================"

groups = threads.map{ |t| t["groups"] }
# puts "after mapping to output"
# puts groups
# puts "test:"
# puts groups.to_s

groups.flatten!
# remove groups that have not enough group members
# puts "======================================"
# puts "bah?"
# puts groups.to_s
# puts groups.class.name
# puts "======================================"
# puts groups[0].to_s
puts "before select"
groupCountDelta = groups.length
groups.select!{ |group| MEMBER_COUNT_MIN <= group.member_count }
puts "after select"
groupCountDelta -= groups.length;

puts "removed #{groupCountDelta} group(s) from processed groups."
puts "total groupCount: #{groups.length}"

# groups.product(groups) do |pair| # this gives us the cartesian product of groups
                                   # onto itself, but I believe this is too expensive.
processedGroups = [];

while 0 < groups.length do
   head = groups.pop
   # groups.each do |other|
   k = 0;
   while k < groups.length
      # puts "comparing: "
      # puts head.president[0..[CHUNK_CUTOFF_LEN, head.president.length].min]
      # puts "against: "
      # puts groups[k].president[0..[CHUNK_CUTOFF_LEN, groups[k].president.length].min]
      dump = Levenshtein.normalized_distance(
         head.president[0..[CHUNK_CUTOFF_LEN, head.president.length].min],
         groups[k].president[0..[CHUNK_CUTOFF_LEN, groups[k].president.length].min]
      )
      # puts "value: #{dump}"
      # puts "----"
      if dump < CUTOFF_VAL then
         head.union! groups[k]
         groups.delete_at k
      end
      k += 1
   end
   processedGroups.push head
end

puts processedGroups.map{|x| puts x.president; puts "="*80 }

# if 1 == groups.length then
#    processedGroups.push groups.last
# end

# we compare all groups presidents to eachother once more, and then...
# now that I think of this, it may be a bit redundant to check groups within the same partiion
# against eachother, we actually can exclude all groups which were in the same partition.

# TODO use find_all to iterate over all other partitions
# arr = []
# arr.find_all

# group = groups.find{ |g|
#    CUTOFF_VAL > Levenshtein.normalized_distance(
#       g.president[0..[CHUNK_CUTOFF_LEN, g.president.length].min],
#       chunk[0..[CHUNK_CUTOFF_LEN, chunk.length].min]
#    )
# }


# itr_x = 0; itr_y = 0;
# while itr_x < groups.length do
#    while itr_y < groups.length do
#       groups[itr_x]
#       itr_x += 1;
#    end
#    itr_y += 1;
# end


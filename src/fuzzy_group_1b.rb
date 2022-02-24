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
   attr_accessor :member_count
   attr_accessor :partition_index

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
   groups = [ ];
   chunks.each do |chunk|
      group = groups.find{ |g|
         CUTOFF_VAL > Levenshtein.normalized_distance(
            g.president[0..[CHUNK_CUTOFF_LEN, g.president.length].min],
            chunk[0..[CHUNK_CUTOFF_LEN, chunk.length].min]
         )
      }
      if group then
         group.member_count += 1;
      else
         groups.push(Group.new(chunk, partition_index))
      end
   end
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

   threadCount += 1;
   if MAX_THREAD_COUNT < threadCount then
      puts "waiting for threads to complete... partition_index: #{partition_index}"
      threads.each{ |thread| thread.join }
      threadCount = 0
   end
end

threads.each{ |thread| thread.join }

groups = threads.map{ |t| t["groups"] }
groups.flatten!

groupCountDelta = groups.length
groups.select!{ |group| MEMBER_COUNT_MIN <= group.member_count }
groupCountDelta -= groups.length;

puts "removed #{groupCountDelta} group(s) from processed groups."
puts "total groupCount: #{groups.length}"

processedGroups = [];

while 0 < groups.length do
   head = groups.pop
   k = 0;
   while k < groups.length
      dump = Levenshtein.normalized_distance(
         head.president[0..[CHUNK_CUTOFF_LEN, head.president.length].min],
         groups[k].president[0..[CHUNK_CUTOFF_LEN, groups[k].president.length].min]
      )
      if dump < CUTOFF_VAL then
         head.union! groups[k]
         groups.delete_at k
      end
      k += 1
   end
   processedGroups.push head
end

puts processedGroups.map{|x| puts x.president; puts "="*80 }

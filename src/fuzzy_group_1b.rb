#!/bin/ruby
require 'levenshtein'

DATE_PATTERN = /\[ [0-9]{2}\.[0-9]{2}\.20[0-9]{2} [0-9]{2}:[0-9]{2} \]/
CUTOFF_VAL = 0.1

MAX_CHUNK_LEN = 5 * 1000;
MAX_PARTITION_LEN = 10 * 1000;
MAX_THREAD_COUNT = 4;
CHUNK_CUTOFF_LEN = 600; # this is sort of bad and should be removed
MEMBER_COUNT_MIN = 3;


class Group
   attr_accessor :president
   # attr_accessor :members
   attr_accessor :member_count
   attr_accessor :parition_index
   def initialize(president = "", parition_index = 0, member_count = 0)
      @president = president
      @parition_index = parition_index
      @members = []
      @member_count = member_count;
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
         # group.members.push(chunk)
         group.member_count += 1;
      else
         groups.push(Group.new(chunk, partition_index))
      end
   end
   return groups
end

def paritionChunks(chunks)
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
end

handle = File.new( ARGV[0], "r")

if not handle then
   puts "ERROR: couldn't open file handle."
   exit true;
end

chunks = handle.sysread(handle.size()).split(DATE_PATTERN);

partitions = paritionChunks(chunks)

threads = []
threadCount = 0;
partitions.map.with_index do |chunks, partition_index|
   threads.push Thread.new{
      Thread.current[:output] = cluster(chunks, partition_index)
   }
   threadCount += 1;
   if MAX_THREAD_COUNT < threadCount then
      threads.map{ |x| x.join }
      threadCount = 0
   end
end

# results.each{ |x| x.join }

# now we still need to merge the results into one big schlong. The bang ! means that we are doing the operation in place, and not making an extra copy of the whole array. We are going from [[grp1, grp2,..], [grp3,..], ... ] to [grp1, grp2, grp3, ...] using the flatten operation.

groups = threads.map{ |t| t[:output] }
groups.flatten!
# remove groups that have not enough group members
groups.select!{ |group| MEMBER_COUNT_MIN <= group.member_count }

# groups.product(groups) do |pair|

itr_x = 0; itr_y = 0;
while itr_x < groups.length do
   while itr_y < groups.length do
      groups[itr_x]
      itr_x += 1;
   end
   itr_y += 1;
end





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

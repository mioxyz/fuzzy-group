# Wikipedia
[Cluster Analysis](https://en.wikipedia.org/wiki/Cluster_analysis)
[Clustering high dim data](https://en.wikipedia.org/wiki/Clustering_high-dimensional_data)
[Cluster Analysis Algos](https://en.wikipedia.org/wiki/Category:Cluster_analysis_algorithms)

this algorithm Affinity propagation seems to be similar to what I'm trying to implement:
[Affinity Propagation](https://en.wikipedia.org/wiki/Affinity_propagation)

## random notes
- for a group, if we additionally log the levenshtein values of each group member, we can gain
  information on the fitness of the president. If the distribution is skewed, that is, the 
  average of the levenshtein distances to the president is large, we know somethings up.
  That gives me an idea: we can dethrone the president if this happens. Since we are 
  throwing away the other member strings after we eval to president, we cannot compare 
  previous members to the potential usurper (but maybe I should do this, but for now it is more
  interesting to have this limitation in place).

## A new Algorithm idea
1. iterate over the dataset and find "large" groups, by not evaluating all combinations of
   all strings, and instead by choosing random pairs of strings.
   Sort the samples by normalized levenshtein distance. For example:
```
   [
      s23 <=> s84  ~> 0.012
      s8  <=> s123 ~> 0.023
      s91 <=> s28  ~> 0.098
      s83 <=> s98  ~> 0.230
      ...
      s37 <=> s47 ~> 0.93
   ] 
```
2. Remove all samples with a score of some cutoff value or remove 90% of samples.

3. Randomly choose 10% of dataset and compare them to all samples.

4. 

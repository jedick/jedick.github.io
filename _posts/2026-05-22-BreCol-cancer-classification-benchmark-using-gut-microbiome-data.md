---
title: "BreCol: Cancer classification benchmark using gut microbiome data"
date: 2026-05-22
last_modified_at: 2026-06-03
layout: single
classes: wide
category: Blog
tags:
  - Microbiome
  - Cancer
  - HyenaDNA
  - Benchmark
header:
  teaser: /assets/siteimages/BreCol_banner.svg
  header: /assets/siteimages/BreCol_banner.svg
  og_image: /assets/siteimages/BreCol_banner.svg
excerpt: "Microbiome-based cancer prediction benchmarks sometimes overestimate real-world performance
  because test samples are drawn from the same studies used for training."
---

## Abstract

Microbiome-based cancer prediction benchmarks sometimes overestimate real-world performance because test samples are drawn from the same studies used for training,
allowing models to exploit study-specific technical artifacts rather than biological signal.
We present BreCol, a temporally structured multi-study compilation of 2,040 16S rRNA sequencing runs covering
breast cancer, colorectal cancer, and healthy cohorts across 26 studies spanning more than a decade.
By reserving the six most recent studies per cancer type as an external holdout,
we ensure that holdout evaluation reflects deployment on data from new laboratories, clinical protocols, and geographic regions.
We evaluate four classifier pipelines: classical (tetramer counts aggregated to run-level frequencies or
unsupervised clustering with cluster abundance profiles (UC/CAP)) and deep learning (HyenaDNA and SetBERT).
Among classical methods, UC/CAP achieves the strongest holdout performance (AUC 0.60 for cancer diagnosis with SVM, 0.83 for cancer type with KNN).
The differential between test (in-study) and holdout AUC is 0.15 points for both tasks
with the best classical classifier, confirming that conventional evaluation inflates apparent model skill.
Both deep-learning pipelines underperform the best classical methods on holdout data;
HyenaDNA (holdout AUC 0.57 for cancer diagnosis, 0.79 for cancer type) edges out SetBERT on generalization.
Our benchmark and associated code are publicly available to support reproducible, credible evaluation of microbiome-based cancer classifiers.

## Introduction

The community of microorganisms inhabiting the human digestive tract, known as the gut microbiome, is increasingly linked to cancer risk and progression.
Clinical studies have associated compositional shifts in gut bacteria with colorectal cancer (CRC)<sup>[1](#ref-ZFL18)</sup>,
and growing evidence implicates gut dysbiosis in breast cancer as well<sup>[2](#ref-YTF+17),[3](#ref-ZXS21)</sup>.
Machine learning models trained on microbiome profiles have shown promise for distinguishing cancer patients from healthy controls within individual cohorts,
raising the prospect of non-invasive, microbiome-based cancer screening<sup>[4](#ref-WPK+19),[5](#ref-SHL+25)</sup>.

The dominant workflow for characterizing the gut microbiome is 16S rRNA amplicon sequencing.
A short, phylogenetically informative region of the bacterial ribosomal gene is amplified and sequenced,
and the resulting reads are matched to known reference taxa to produce species- or genus-level abundance tables.
Most machine learning studies operate on these pre-processed abundance tables, treating the raw sequence data as an intermediate artifact to discard.
This discards potentially informative signal: fine-grained genetic variation within taxa, sequences with no close reference in curated databases,
and compositional structure at the level of individual reads within a sample.
Methods that work directly on raw sequence data or on reference-free sequence features can in principle recover this signal.

A deeper problem, however, arises when test sets are constructed by random sampling from the same studies used for training.
This creates optimistically biased performance estimates that do not reflect real-world deployment.
In microbiome studies the bias is especially severe because technical factors (e.g. primer choice and sequencing platform) and
regional microbiome variation introduce large study-level signals that a model can exploit without learning any biology<sup>[6](#ref-WSNP22)</sup>.
As a specific example, Sun et al.<sup>[5](#ref-SHL+25)</sup> found lower AUC for leave-one-dataset-out (LODO) than for cross-validation (CV)
in CRC prediction from 16S-based taxonomic profiles (average AUC for CV: 0.82, LODO: 0.77).

This problem is exacerbated for cancer type prediction (a different task from cancer vs healthy prediction).
Breast and colorectal cancer samples almost always come from entirely separate studies,
so a classifier can achieve near-perfect in-study accuracy simply by identifying the study of origin rather than the disease.
Evaluating such a model on test samples from the same studies dramatically overestimates generalization.

Reliable benchmarks for both cancer diagnosis and type prediction must evaluate models on one or more “prediction sets”<sup>[6](#ref-WSNP22)</sup>,
i.e. studies never encountered during training, which we refer to as holdout studies.
To to this, we curated a new compilation of 2,040 16S rRNA sequencing runs spanning 26 studies (13 breast cancer, 13 colorectal cancer),
covering healthy controls and two cancer types across studies from 2013 to 2026.
Studies are partitioned chronologically: the first seven studies per cancer type form the development set (training, validation, and test),
while the more recent six studies per cancer type are reserved as an external holdout.
The temporal and study-level separation in this benchmark provides a demanding but credible measure of real-world generalizability.

Against this benchmark we evaluate a progression of feature representations and learning approaches (Figure 1).
For classical machine learning we use either run-level aggregated tetramer frequencies or UC/CAP cluster abundance profiles.
For deep learning we fine-tune two pre-trained sequence models:
HyenaDNA, which encodes packed sets of sequences with a mean-pooled token representation,
and SetBERT, which contextualizes individual reads within their parent sample.
Both models are described in the **Models** section below.

<figure>
<img src="/assets/images/2026-05-22-BreCol-cancer-classification-benchmark-using-gut-microbiome-data/figure1_pipelines.svg" alt="Classification pipelines." />
<figcaption>Figure 1: Classification pipelines.</figcaption>
</figure>

Our main contributions are (1) a custom curated, temporally structured multi-study benchmark for microbiome-based cancer classification
that provides more reliable estimates of real-world performance than within-study splits,
(2) a reference-free cluster abundance profile method that achieves the best overall holdout performance among our tested models,
and (3) a comparison of two deep-learning sequence models (HyenaDNA and SetBERT) showing that both trail the best classical methods on holdout data,
with HyenaDNA generalizing somewhat better than SetBERT.

## Models

### Classical machine learning

Rather than performing taxonomic classification, we count tetramer occurrences in each raw 16S sequence
to generate a 256-dimensional feature space from sequence composition alone.
Tetramer frequencies, also known as tetranucleotide frequencies, have proven useful for taxonomic binning of metagenomic sequences<sup>[7](#ref-DAB+09)</sup>.
Tetramer counting is a specific instance of *k*-mer counting, which has recently gained interest
as an efficient, reference-free method for feature engineering in microbiome machine learning<sup>[8](#ref-Bok25)</sup>.

For run-level features, tetramer counts are summed across all sequences in a run and converted to relative frequencies.
Because these run-level features are averages, they lose within-run compositional structure, i.e.
information about which sequence types tend to co-occur in the same sample.
Taxonomic profiling preserves this structure through genus- or species-level groupings,
but taxonomic assignment is not the only route to sequence similarity clusters.

Here we introduce unsupervised clustering with cluster abundance profiles (UC/CAP).
Rather than averaging across all sequences, UC/CAP build sequence clusters with similar tetramer composition
and then profiles the cluster membership of a large number of sequences from each run.
This approach is analogous in purpose to operational taxonomic unit (OTU)-based methods, but entirely reference-free.

### Deep learning

**HyenaDNA**<sup>[9](#ref-NPF+23)</sup> is a long-range genomic sequence model pre-trained on the human reference genome.
It uses single-nucleotide tokens and a Hyena operator to process sequences of up to 1 million bases.
For each sequencing run we pack sequences into sets (up to 16k nucleotides per set, 5 sets per run)
and mean-pool the per-position hidden states of the backbone to produce a single vector for classification.
Because this pooled representation collapses all sequences in a set into one vector,
it cannot capture within-run compositional structure, a limitation shared with run-level tetramer aggregation.

**SetBERT**<sup>[10](#ref-LGA+25)</sup> is a transformer architecture designed specifically for high-throughput sequencing data.
It represents each read with a DNABERT sequence encoder (3-mer tokens, 768-dimensional embeddings in the released *qiita-16s* checkpoint)
and then contextualizes the full set of reads from one run with a stack of Set Attention Blocks (SABs).
SABs are standard transformer blocks without positional encoding, making the model permutation-equivariant.
A learned class token (\[CLS\]) prepended to the set is conditioned on all reads by the SABs;
its output embedding summarizes the entire run and serves as input to the classification head.
Unlike HyenaDNA, SetBERT was pre-trained on approximately 280,000 microbial 16S amplicon samples
with a relative-abundance prediction objective<sup>[10](#ref-LGA+25)</sup>,
making its learned representations relevant to the domain.

Key differences between the two models are summarized in Table 1.

<table>
<caption>Table 1: Comparison of HyenaDNA and SetBERT models.</caption>
<colgroup>
<col style="width: 14%" />
<col style="width: 42%" />
<col style="width: 42%" />
</colgroup>
<thead>
<tr>
<th></th>
<th style="text-align: center;">HyenaDNA</th>
<th style="text-align: center;">SetBERT</th>
</tr>
</thead>
<tbody>
<tr>
<td>Pre-training domain</td>
<td style="text-align: center;">Human genome</td>
<td style="text-align: center;">Microbial 16S</td>
</tr>
<tr>
<td>Tokenization</td>
<td style="text-align: center;">Single nucleotides</td>
<td style="text-align: center;">Overlapping 3-mers</td>
</tr>
<tr>
<td>Run representation</td>
<td style="text-align: center;">Mean-pooled hidden states</td>
<td style="text-align: center;">[CLS] token (context-aware)</td>
</tr>
<tr>
<td>Sequences per run</td>
<td style="text-align: center;">~323 ± 112 (at 16k/set, 5 sets)</td>
<td style="text-align: center;">350</td>
</tr>
<tr>
<td>Sequence length limit</td>
<td style="text-align: center;">Not truncated (packed to context)</td>
<td style="text-align: center;">Trimmed to 150 bp</td>
</tr>
</tbody>
</table>

Although HyenaDNA offers larger context lengths (up to 1 million bases) and SetBERT was pre-trained with 1000 sequences per run
and tested with up to 10,000 sequences per run<sup>[10](#ref-LGA+25)</sup>, we use a smaller number of sequences due to lower GPU resources (16 GB GPU RAM) available in our study.

### Classification heads

For both models we tried three classification head architectures applied to the run-level summary vector.
A **linear** head is a single fully connected layer mapping the embedding to a scalar logit;
this is the simplest option and the one used in the original HyenaDNA paper.
An **MLP** (multi-layer perceptron) head adds a hidden layer (256 units, GELU activation, 0.1 dropout)
before the output layer, giving the classifier more capacity to learn non-linear decision boundaries.
A **cosine similarity** head projects the embedding onto a single learned direction, scoring it by cosine similarity scaled by a learnable temperature.
Because cosine similarity is direction-only, it is sensitive to the orientation of the embedding vector rather than its magnitude.
The SetBERT pre-training objective uses a linear head with softmax for relative abundance prediction, so the linear head is the closest to the pre-trained regime.

For both models we used a learning rate of 1×10<sup>-4</sup> for the classification head
and 1×10<sup>-5</sup> for the backbone (a 10× reduction to preserve pre-trained representations).
Models were trained for 5 epochs and the epoch with the highest validation AUC was selected.

## Methods

### Data curation

Each sample corresponds to a sequencing run containing multiple 16S rRNA gene sequences.
We collected sequencing runs from studies covering breast cancer and colorectal cancer;
studies were only included if both cancer-positive and healthy control labels were available.
We stored SRA Run accessions (beginning with SRR, ERR, or DRR) and study metadata in the repository and downloaded each run’s read archive from NCBI.

Our compilation spans 26 studies in total: 13 for breast cancer and 13 for colorectal cancer (Table 2).
Arranged chronologically by publication year, the first seven studies per cancer type form the development partition
(train, validation, and test splits), and the more recent six studies per cancer type are reserved as the holdout partition.
Development and holdout sets are separated not only by study boundaries but also by time: all holdout studies are from 2023 onward.
This design makes the benchmark a realistic challenge: predictions must transfer to future datasets available only after the model was trained.

<table>
<caption>Table 2: Breast and colorectal cancer studies included in the
BreCol compilation, arranged chronologically by publication year and
partitioned into development (first seven studies per cancer type) and
holdout (remaining six per cancer type) sets. Sample counts reflect
counts after stratified subsampling at the indicated rate.</caption>
<thead>
<tr>
<th>Ref</th>
<th>Year</th>
<th>Type</th>
<th>Cancer</th>
<th>Healthy</th>
<th>Rate</th>
<th>BioProject</th>
<th>Partition</th>
</tr>
</thead>
<tbody>
<tr>
<td><span class="citation" data-cites="AAM+13"><sup><a
href="#ref-AAM+13" role="doc-biblioref">11</a></sup></span></td>
<td>2013</td>
<td>breast</td>
<td>29</td>
<td>32</td>
<td>1</td>
<td>PRJNA396901</td>
<td>development</td>
</tr>
<tr>
<td><span class="citation" data-cites="GJH+15"><sup><a
href="#ref-GJH+15" role="doc-biblioref">12</a></sup></span></td>
<td>2015</td>
<td>breast</td>
<td>47</td>
<td>47</td>
<td>1</td>
<td>PRJNA345373</td>
<td>development</td>
</tr>
<tr>
<td><span class="citation" data-cites="GHB+18"><sup><a
href="#ref-GHB+18" role="doc-biblioref">13</a></sup></span></td>
<td>2018</td>
<td>breast</td>
<td>48</td>
<td>48</td>
<td>1</td>
<td>PRJNA383849</td>
<td>development</td>
</tr>
<tr>
<td><span class="citation" data-cites="BVW+21"><sup><a
href="#ref-BVW+21" role="doc-biblioref">14</a></sup></span></td>
<td>2021</td>
<td>breast</td>
<td>57</td>
<td>63</td>
<td>0.15</td>
<td>PRJNA658160</td>
<td>development</td>
</tr>
<tr>
<td><span class="citation" data-cites="BSR+22"><sup><a
href="#ref-BSR+22" role="doc-biblioref">15</a></sup></span></td>
<td>2022</td>
<td>breast</td>
<td>19</td>
<td>14</td>
<td>1</td>
<td>PRJEB54599</td>
<td>development</td>
</tr>
<tr>
<td><span class="citation" data-cites="WZK+22"><sup><a
href="#ref-WZK+22" role="doc-biblioref">16</a></sup></span></td>
<td>2022</td>
<td>breast</td>
<td>54</td>
<td>25</td>
<td>1</td>
<td>PRJNA804967</td>
<td>development</td>
</tr>
<tr>
<td><span class="citation" data-cites="ZZZ+22"><sup><a
href="#ref-ZZZ+22" role="doc-biblioref">17</a></sup></span></td>
<td>2022</td>
<td>breast</td>
<td>14</td>
<td>14</td>
<td>1</td>
<td>PRJNA726050</td>
<td>development</td>
</tr>
<tr>
<td><span class="citation" data-cites="SKC+23"><sup><a
href="#ref-SKC+23" role="doc-biblioref">18</a></sup></span></td>
<td>2023</td>
<td>breast</td>
<td>22</td>
<td>21</td>
<td>1</td>
<td>PRJNA872152</td>
<td>holdout</td>
</tr>
<tr>
<td><span class="citation" data-cites="LBA+25"><sup><a
href="#ref-LBA+25" role="doc-biblioref">19</a></sup></span></td>
<td>2025</td>
<td>breast</td>
<td>76</td>
<td>16</td>
<td>1</td>
<td>PRJNA1127492</td>
<td>holdout</td>
</tr>
<tr>
<td><span class="citation" data-cites="SYL+25"><sup><a
href="#ref-SYL+25" role="doc-biblioref">20</a></sup></span></td>
<td>2025</td>
<td>breast</td>
<td>10</td>
<td>10</td>
<td>1</td>
<td>PRJNA1243283</td>
<td>holdout</td>
</tr>
<tr>
<td><span class="citation" data-cites="MTK+26"><sup><a
href="#ref-MTK+26" role="doc-biblioref">21</a></sup></span></td>
<td>2026</td>
<td>breast</td>
<td>32</td>
<td>32</td>
<td>1</td>
<td>PRJNA914483</td>
<td>holdout</td>
</tr>
<tr>
<td><span class="citation" data-cites="SVK+26"><sup><a
href="#ref-SVK+26" role="doc-biblioref">22</a></sup></span></td>
<td>2026</td>
<td>breast</td>
<td>22</td>
<td>30</td>
<td>1</td>
<td>PRJNA1356467</td>
<td>holdout</td>
</tr>
<tr>
<td><span class="citation" data-cites="YTK+26"><sup><a
href="#ref-YTK+26" role="doc-biblioref">23</a></sup></span></td>
<td>2026</td>
<td>breast</td>
<td>15</td>
<td>15</td>
<td>1</td>
<td>PRJNA1190698</td>
<td>holdout</td>
</tr>
<tr>
<td><span class="citation" data-cites="ZTV+14"><sup><a
href="#ref-ZTV+14" role="doc-biblioref">24</a></sup></span></td>
<td>2014</td>
<td>colorectal</td>
<td>41</td>
<td>75</td>
<td>1</td>
<td>PRJEB6070</td>
<td>development</td>
</tr>
<tr>
<td><span class="citation" data-cites="BRRS16"><sup><a
href="#ref-BRRS16" role="doc-biblioref">25</a></sup></span></td>
<td>2016</td>
<td>colorectal</td>
<td>64</td>
<td>94</td>
<td>0.5</td>
<td>PRJNA290926</td>
<td>development</td>
</tr>
<tr>
<td><span class="citation" data-cites="OKN+21"><sup><a
href="#ref-OKN+21" role="doc-biblioref">26</a></sup></span></td>
<td>2021</td>
<td>colorectal</td>
<td>67</td>
<td>51</td>
<td>0.1</td>
<td>PRJDB11246</td>
<td>development</td>
</tr>
<tr>
<td><span class="citation" data-cites="YDS+21"><sup><a
href="#ref-YDS+21" role="doc-biblioref">27</a></sup></span></td>
<td>2021</td>
<td>colorectal</td>
<td>65</td>
<td>43</td>
<td>0.35</td>
<td>PRJNA763023</td>
<td>development</td>
</tr>
<tr>
<td><span class="citation" data-cites="YWS+21"><sup><a
href="#ref-YWS+21" role="doc-biblioref">28</a></sup></span></td>
<td>2021</td>
<td>colorectal</td>
<td>53</td>
<td>52</td>
<td>1</td>
<td>PRJEB36789</td>
<td>development</td>
</tr>
<tr>
<td><span class="citation" data-cites="DLT+22"><sup><a
href="#ref-DLT+22" role="doc-biblioref">29</a></sup></span></td>
<td>2022</td>
<td>colorectal</td>
<td>27</td>
<td>33</td>
<td>1</td>
<td>PRJNA824020</td>
<td>development</td>
</tr>
<tr>
<td><span class="citation" data-cites="PCL+22"><sup><a
href="#ref-PCL+22" role="doc-biblioref">30</a></sup></span></td>
<td>2022</td>
<td>colorectal</td>
<td>36</td>
<td>25</td>
<td>1</td>
<td>PRJNA662014</td>
<td>development</td>
</tr>
<tr>
<td><span class="citation" data-cites="BWY+23"><sup><a
href="#ref-BWY+23" role="doc-biblioref">31</a></sup></span></td>
<td>2023</td>
<td>colorectal</td>
<td>46</td>
<td>43</td>
<td>1</td>
<td>PRJEB53415</td>
<td>holdout</td>
</tr>
<tr>
<td><span class="citation" data-cites="BRR+24"><sup><a
href="#ref-BRR+24" role="doc-biblioref">32</a></sup></span></td>
<td>2024</td>
<td>colorectal</td>
<td>51</td>
<td>51</td>
<td>1</td>
<td>PRJEB71787</td>
<td>holdout</td>
</tr>
<tr>
<td><span class="citation" data-cites="CAB+24"><sup><a
href="#ref-CAB+24" role="doc-biblioref">33</a></sup></span></td>
<td>2024</td>
<td>colorectal</td>
<td>90</td>
<td>30</td>
<td>1</td>
<td>PRJNA911189</td>
<td>holdout</td>
</tr>
<tr>
<td><span class="citation" data-cites="SGH+24"><sup><a
href="#ref-SGH+24" role="doc-biblioref">34</a></sup></span></td>
<td>2024</td>
<td>colorectal</td>
<td>10</td>
<td>10</td>
<td>1</td>
<td>PRJNA1059759</td>
<td>holdout</td>
</tr>
<tr>
<td><span class="citation" data-cites="ARF+25"><sup><a
href="#ref-ARF+25" role="doc-biblioref">35</a></sup></span></td>
<td>2025</td>
<td>colorectal</td>
<td>25</td>
<td>15</td>
<td>1</td>
<td>PRJEB76625</td>
<td>holdout</td>
</tr>
<tr>
<td><span class="citation" data-cites="GYX+25"><sup><a
href="#ref-GYX+25" role="doc-biblioref">36</a></sup></span></td>
<td>2025</td>
<td>colorectal</td>
<td>67</td>
<td>64</td>
<td>0.6</td>
<td>PRJNA1092526</td>
<td>holdout</td>
</tr>
<tr>
<td></td>
<td></td>
<td></td>
<td></td>
<td></td>
<td></td>
<td>PRJNA1092376</td>
<td></td>
</tr>
</tbody>
</table>

Some studies have substantially larger sample counts than others.
To improve study balance, we applied random sampling within several studies (stratified by cancer-versus-healthy label).
The sample sizes in Table 2 reflect counts after sampling at the indicated rate; these samples are flagged as `sample_used=TRUE` in the data CSV files.
Additionally, for two studies (<sup>[14](#ref-BVW+21)</sup> and<sup>[33](#ref-CAB+24)</sup>) we excluded runs with \<2000 spots.

### Preprocessing, splits, and sampling

We normalized sample labels to a restricted vocabulary: healthy, breast cancer, and colorectal cancer.
Breast cancer samples include invasive tumors; colorectal cancer samples include carcinoma.
Any benign samples (e.g. adenomas, benign colon polyps, and breast ductal carcinoma in situ (DCIS))
and non-fecal samples in the studies were excluded from our analysis.

Among development studies, we assigned each sequencing run to stratified training, validation, or test sets in a 70:10:20 ratio.
Runs from holdout studies were excluded from this assignment.
Split assignments were defined in advance from study lists and per-study sample tables, independent of any downstream feature computation.

We held the validation set fixed (no cross-validation).
This allows the same development splits to be used consistently across both the classical and HyenaDNA pipelines,
since GPU-intensive language model training makes repeated cross-validation expensive.
The same run-level split underlies both classification tasks: cancer versus healthy (cancer diagnosis) on all samples,
and breast versus colorectal (cancer type) restricted to cancer-positive samples.

For all classification pipelines we dropped the first 1000 sequences in each run as a quality control measure.
We then randomly sampled up to 5000 sequences from the remaining sequences in each run for tetramer and UC/CAP feature computation.
For HyenaDNA, sequences were packed into sets up to 16k positions rather than sampled to a fixed count.

### Run-level tetramer frequencies and classification pipeline

We calculated tetramer frequencies for each run by counting all 4-mers within each sequence,
summing counts over all sequences in the run, then converting to relative frequencies, yielding a 256-dimensional feature vector per run.

For the majority-class baseline, we predict the most frequent class in the training set for all samples.

#### Hyperparameter grid search

Table 3 lists the hyperparameter values used for grid search.

<table>
<caption>Table 3: Classifier models and hyperparameter grids used in
run-level tetramer frequency classification and in UC/CAP classification
for tetramer counts.</caption>
<colgroup>
<col style="width: 50%" />
<col style="width: 50%" />
</colgroup>
<thead>
<tr>
<th>Model</th>
<th>Hyperparameters</th>
</tr>
</thead>
<tbody>
<tr>
<td>KNN</td>
<td>PCA n_components (none, 0.95), n_neighbors (5, 15)</td>
</tr>
<tr>
<td>SVM</td>
<td>PCA n_components (none, 0.95), C (1.0, 10.0)</td>
</tr>
<tr>
<td>Random Forest</td>
<td>n_estimators (200, 500), max_depth (none, 10), min_samples_leaf (1,
2)</td>
</tr>
</tbody>
</table>

For both KNN and SVM we applied a centered log-ratio transform (CLR), standardized the CLR coordinates, then applied PCA.
For KNN we used inverse distance weighting and tuned the PCA components and number of neighbors.
For SVM, we used an RBF kernel and tuned the PCA components and penalty parameter *C*.
The kernel width parameter *gamma* was left at scikit-learn’s default (‘scale’).

For random forest, we used the same CLR and standardization but omitted PCA.
We tuned the number of trees, maximum tree depth, and minimum samples per leaf.

After selecting hyperparameters using area under the receiver operating characteristic (ROC) curve (AUC) by grid search on the validation split,
we fit each final pipeline on the training split.

### Cluster abundance profiles for tetramer counts

Run-level tetramer features summarize each sample with a single aggregate profile and do not capture how different sequence types are distributed within a run.
To preserve this within-run compositional structure, we use unsupervised clustering followed by cluster abundance profiles (UC/CAP),
a reference-free and alignment-free approach.

Because the sequence-level table is large, we first fit the unsupervised clustering model using only sequences from training-split runs,
drawing at most a fixed number of sequences per run.
For each selected sequence we computed a 256-dimensional tetramer composition vector,
then fit *k*-means to all selected sequences to obtain *K* centroids defining a sequence codebook.
Dimensionality reduction with PCA before *k*-means was trialed and found to degrade downstream classification results, so it was not used here.

To construct run-level features, we applied the same centroid assignments (without refitting)
to a larger per-run sequence budget for every run in the sequence-level table, including validation, test, and holdout runs.
We counted cluster memberships within each run and normalized by the number of assigned sequences to produce a *K*-dimensional cluster abundance profile (CAP).
These CAP vectors serve as the feature matrix for supervised classification on both binary tasks, with downstream classifiers selected separately per task.

### HyenaDNA fine-tuning

We fine-tuned HyenaDNA on 16S rRNA sequence data.
To use the available context window (up to 16k positions in our experiments),
we packed sequences from each run into sets and generated 5 sets per run.

We initialized HyenaDNA from the *hyenadna-small-32k-seqlen* pre-trained checkpoint and fine-tuned one model per binary task,
each with its own classification head on the shared backbone.
Cross-entropy loss was computed per task; because each run produces multiple sequence sets,
training loss was averaged across all valid sets for a run.
At evaluation, set-level logits were averaged to obtain one prediction per run,
then AUC was computed on the same splits used for the classical pipelines.

Backbone hidden states were mean-pooled across sequence positions before the classification head.
Batch size was adjusted to maximize GPU memory utilization.

### SetBERT fine-tuning

We used the released *qiita-16s* checkpoint: a 12-layer DNABERT encoder embeds each amplicon read into a 768-dimensional vector,
and a 6-layer SAB transformer with 12 heads contextualizes the set of read embeddings,
producing a \[CLS\] token embedding that summarizes the run.
The configuration of the available checkpoint differs somewhat from the model described in the paper
(DNABERT: 8 transformer layers with 8 attention heads and 64-d embedding vector; 8 SAB layers each with 8 attention heads<sup>[10](#ref-LGA+25)</sup>).

For each binary task we attached a classification head to the \[CLS\] token and trained with binary cross-entropy.
We used 350 reads per run, trimmed each read to 150 base pairs (following the original SetBERT paper<sup>[10](#ref-LGA+25)</sup>),
and tokenized into overlapping 3-mers using the DNABERT tokenizer bundled with the checkpoint.
The set size of 350 (compared to 1,000 in the SetBERT paper) was chosen to fit within 16 GB of GPU memory.

During development we found that the SetBERT model code wraps the per-read DNABERT forward pass
in PyTorch’s activation-checkpointing utility with `use_reentrant=True`.
Because the wrapped call only receives integer token IDs (which cannot carry gradients),
the reentrant checkpoint silently drops the backward path through the encoder,
so DNABERT parameters never receive gradients even when nominally trainable.
We patched the upstream model to use `use_reentrant=False`, which uses saved-tensor rematerialization
to propagate gradients to the encoder parameters correctly,
and confirmed the fix by verifying that all encoder parameters have nonzero gradients after one backward step.

### Implementation

The benchmark dataset is composed of CSV files with instructions and scripts for downloading data from NCBI and preprocessing.
The project code is written in Python with YAML configuration and a Makefile-driven analysis pipeline.
The official HyenaDNA implementation was modified for this project and structured as a pip-installable package for import by analysis scripts.
After downloading, the entire pipeline runs in ca. 22 hours on a machine with 8 CPU cores, 40 GB of RAM, and a 16 GB NVIDIA GPU.

## Results

We define two binary classification tasks: **cancer diagnosis** (cancer vs. healthy, all samples)
and **cancer type** (breast vs. colorectal, cancer-positive samples only).
Performance is reported as AUC on the test split (unseen samples from the development studies used to train the model)
and the holdout split (entirely unseen studies).

For cancer type, all development studies for breast cancer are separate from all development studies for colorectal cancer.
A model can therefore exploit study-level signals, e.g. different sequencing protocols, primer sets, or regional microbiome composition,
as a near-perfect shortcut for in-study test performance.
Holdout performance, where the model encounters new studies it has not seen during training, removes this shortcut.
We accordingly expect cancer type to be the *easier* task for in-study test data but the *harder* task for holdout data.

For cancer diagnosis, each included study contains both cancer-positive and healthy samples,
so study identity alone does not predict the label. Models must learn biological differences between cancer and healthy microbiomes within studies,
and those differences are expected to transfer, at least partially, to new studies.

### Classification with run-level tetramer frequencies

All models exceed the majority-class baseline on the test split, with particularly large margins for cancer type prediction (Table 4).
The holdout picture is sharply different.
For cancer diagnosis, SVM achieves a modest AUC of 0.59 while random forest and KNN fall closer to baseline.
For cancer type, SVM reaches an AUC of 0.71 while KNN collapses below baseline on holdout.

<table>
<caption>Table 4: Test and holdout AUC for run-level tetramer frequency
classification with the majority-class baseline, KNN, SVM, and random
forest. Bold marks the best value per column.</caption>
<thead>
<tr>
<th rowspan="2">Model</th>
<th colspan="2">Cancer diagnosis</th>
<th colspan="2">Cancer type</th>
</tr>
<tr>
<th>Test</th>
<th>Holdout</th>
<th>Test</th>
<th>Holdout</th>
</tr>
</thead>
<tbody>
<tr>
<td>Majority class</td>
<td>0.50</td>
<td>0.50</td>
<td>0.50</td>
<td>0.50</td>
</tr>
<tr>
<td>KNN</td>
<td>0.71</td>
<td>0.58</td>
<td>0.96</td>
<td>0.41</td>
</tr>
<tr>
<td>SVM</td>
<td>0.70</td>
<td><strong>0.59</strong></td>
<td><strong>0.996</strong></td>
<td><strong>0.71</strong></td>
</tr>
<tr>
<td>Random Forest</td>
<td><strong>0.73</strong></td>
<td>0.57</td>
<td>0.99</td>
<td>0.66</td>
</tr>
</tbody>
</table>

### Classification with cluster abundance profiles for tetramer counts

We explored six combinations of the three UC/CAP hyperparameters defined by *n*<sub>UC</sub> (sequences per run used for unsupervised clustering),
*K* (number of clusters), and *n*<sub>CAP</sub> (sequences per run assigned to centroids and used to build cluster abundance profiles) (Table 5).

<table>
<caption>Table 5: UC/CAP feature sets.</caption>
<colgroup>
<col style="width: 12%" />
<col style="width: 12%" />
<col style="width: 12%" />
<col style="width: 12%" />
<col style="width: 12%" />
<col style="width: 12%" />
<col style="width: 12%" />
<col style="width: 12%" />
</colgroup>
<thead>
<tr>
<th>Feature set</th>
<th><em>n</em>UC</th>
<th><em>K</em></th>
<th><em>n</em>CAP</th>
<th>Feature set</th>
<th><em>n</em>UC</th>
<th><em>K</em></th>
<th><em>n</em>CAP</th>
</tr>
</thead>
<tbody>
<tr>
<td>1</td>
<td>500</td>
<td>1000</td>
<td>500</td>
<td>4</td>
<td>1000</td>
<td>1000</td>
<td>5000</td>
</tr>
<tr>
<td>2</td>
<td>1000</td>
<td>1000</td>
<td>1000</td>
<td>5</td>
<td>1000</td>
<td>2000</td>
<td>5000</td>
</tr>
<tr>
<td>3</td>
<td>1000</td>
<td>2000</td>
<td>1000</td>
<td>6</td>
<td>1000</td>
<td>3000</td>
<td>5000</td>
</tr>
</tbody>
</table>

These UC/CAP parameters produced six different cluster abundance profiles (or feature sets) used for standard supervised classification
with the models and hyperparameter grids described above (Table 3).
SVM achieves higher holdout AUC than KNN across feature sets for cancer diagnosis, but the pattern is reversed for cancer type, where KNN leads (Figure 2).
For cancer type, both models show near-perfect in-study test performance across feature sets, but holdout values drop sharply.

<figure>
<img src="/assets/images/2026-05-22-BreCol-cancer-classification-benchmark-using-gut-microbiome-data/figure2_tetramer_uc_cap.svg" alt="Feature-set stability for UC/CAP with tetramer counts in SVM and KNN." />
<figcaption>Figure 2: Feature-set stability for UC/CAP with tetramer counts in SVM and KNN.</figcaption>
</figure>

Table 6 shows the results for the best UC/CAP feature set as judged by *test* AUC in each task,
so we can legitimately assess holdout performance on unseen studies.
For cancer diagnosis, SVM achieves the best holdout performance, followed by random forest and KNN.
For cancer type, KNN leads on holdout, followed by random forest and SVM.

The gap between in-study test and holdout is again large for cancer type, but UC/CAP with KNN achieves substantially higher cancer type holdout AUC
than any tetramer-based classifier, demonstrating that richer within-run compositional features partially attenuate the study-level shortcut problem.

<table>
<caption>Table 6: Test and holdout AUC for UC/CAP cluster abundance
profiles built from tetramer counts, with the best feature set selected
per task by test AUC.</caption>
<thead>
<tr>
<th rowspan="2">Model</th>
<th colspan="2">Cancer diagnosis</th>
<th colspan="2">Cancer type</th>
</tr>
<tr>
<th>Test</th>
<th>Holdout</th>
<th>Test</th>
<th>Holdout</th>
</tr>
</thead>
<tbody>
<tr>
<td>KNN</td>
<td>0.69</td>
<td>0.54</td>
<td>0.998</td>
<td><strong>0.83</strong></td>
</tr>
<tr>
<td>SVM</td>
<td><strong>0.77</strong></td>
<td><strong>0.60</strong></td>
<td><strong>1.00</strong></td>
<td>0.74</td>
</tr>
<tr>
<td>Random Forest</td>
<td>0.74</td>
<td>0.57</td>
<td>1.000</td>
<td>0.79</td>
</tr>
<tr>
<td>Feature set</td>
<td colspan="2">5</td>
<td colspan="2">5</td>
</tr>
</tbody>
</table>

### Classification with HyenaDNA

For each task we fine-tuned a HyenaDNA model from the pre-trained backbone.
The results with different head architectures are shown in Table 7.
For cancer diagnosis, test and holdout AUC are similar across all three heads (around 0.61–0.62 test, 0.54–0.57 holdout),
suggesting that head choice matters little for this task.
For cancer type, all heads show similar test AUC (0.88–0.89) and the MLP head achieves the highest holdout AUC (0.79),
though with the largest standard deviation (±0.10), indicating some instability across seeds.
Linear and cosine heads both reach 0.74 on holdout.

<table>
<caption>Table 7: HyenaDNA fine-tuning results with 5 sets at 2048 max
length per set, reported as mean ± standard deviation across three
random seeds.</caption>
<thead>
<tr>
<th rowspan="2">Ablation</th>
<th colspan="2">Cancer diagnosis</th>
<th colspan="2">Cancer type</th>
</tr>
<tr>
<th>Test</th>
<th>Holdout</th>
<th>Test</th>
<th>Holdout</th>
</tr>
</thead>
<tbody>
<tr>
<td>Linear head</td>
<td>0.61 <span class="small">± 0.02</span></td>
<td><strong>0.57</strong> <span class="small">± 0.02</span></td>
<td>0.88 <span class="small">± 0.01</span></td>
<td>0.74 <span class="small">± 0.07</span></td>
</tr>
<tr>
<td>MLP head</td>
<td>0.61 <span class="small">± 0.04</span></td>
<td>0.54 <span class="small">± 0.03</span></td>
<td>0.88 <span class="small">± 0.02</span></td>
<td><strong>0.79</strong> <span class="small">± 0.10</span></td>
</tr>
<tr>
<td>Cosine head</td>
<td><strong>0.62</strong> <span class="small">± 0.01</span></td>
<td>0.55 <span class="small">± 0.02</span></td>
<td><strong>0.89</strong> <span class="small">± 0.01</span></td>
<td>0.74 <span class="small">± 0.08</span></td>
</tr>
</tbody>
</table>

We used the linear head (the configuration with the best holdout AUC for cancer diagnosis) to study the effect of context length.
We varied the length per set (1k, 2k, 4k, 8k, and 16k positions), obtaining shorter configurations by truncating a single large cache built at 16k.
Figure 3 shows that for cancer diagnosis, holdout AUC increases modestly from 2k to 8k before leveling off,
while for cancer type, 2k is best on holdout and longer contexts markedly reduce holdout AUC despite slight gains on the test split.
The divergence between test and holdout trends for cancer type suggests that larger contexts allow the model to pick up study-specific signals.

<figure>
<img src="/assets/images/2026-05-22-BreCol-cancer-classification-benchmark-using-gut-microbiome-data/figure3_hyenadna.svg" alt="Effect of context length per set on HyenaDNA AUC for cancer diagnosis (left) and cancer type (right), using the linear head with three random seeds." />
<figcaption>Figure 3: Effect of context length per set on HyenaDNA AUC for cancer diagnosis (left) and cancer type (right),
using the linear head with three random seeds.</figcaption>
</figure>

### Classification with SetBERT

We evaluated the same three classification heads on SetBERT (Table 8).
For cancer diagnosis, test and holdout AUC are similar across heads (0.61–0.64 test, 0.54–0.56 holdout), as with HyenaDNA.
For cancer type, the pattern differs: test AUC is simila across heads (0.97–0.98), while the cosine head is best on holdout (0.70)
and the MLP head is the worst on holdout (0.56 ± 0.16), with substantially higher variance than the other two heads.

<table>
<caption>Table 8: SetBERT fine-tuning results with a per-run set size of
350 sequences, reported as mean ± standard deviation across two random
seeds.</caption>
<thead>
<tr>
<th rowspan="2">Ablation</th>
<th colspan="2">Cancer diagnosis</th>
<th colspan="2">Cancer type</th>
</tr>
<tr>
<th>Test</th>
<th>Holdout</th>
<th>Test</th>
<th>Holdout</th>
</tr>
</thead>
<tbody>
<tr>
<td>Linear head</td>
<td><strong>0.64</strong> <span class="small">± 0.03</span></td>
<td>0.54 <span class="small">± 0.02</span></td>
<td><strong>0.98</strong> <span class="small">± 0.01</span></td>
<td>0.65 <span class="small">± 0.05</span></td>
</tr>
<tr>
<td>MLP head</td>
<td>0.61 <span class="small">± 0.03</span></td>
<td><strong>0.56</strong> <span class="small">± 0.02</span></td>
<td>0.98 <span class="small">± 0.02</span></td>
<td>0.56 <span class="small">± 0.16</span></td>
</tr>
<tr>
<td>Cosine head</td>
<td>0.63 <span class="small">± 0.00</span></td>
<td>0.56 <span class="small">± 0.03</span></td>
<td>0.97 <span class="small">± 0.00</span></td>
<td><strong>0.70</strong> <span class="small">± 0.06</span></td>
</tr>
</tbody>
</table>

## Discussion

Results are consistently lower on holdout splits than on in-study test splits,
confirming that test performance within the same studies used for training gives optimistic estimates of real-world model skill.
For run-level tetramer frequencies, the stark contrast betwen test and holdout performance (AUC \>0.9 for test vs 0.71 or less for holdout)
indicates that classifiers overfit to study-level signals when trained on single-study cancer-type data.
Fitting to cluster abundance profiles (UC/CAP) preserves within-run compositional information
and improves holdout performance on cancer type but not on the cancer diagnosis task.

We list our per-study AUC for cancer diagnosis and comparisons with colorectal cancer where available (Table 9).
On two of the three development studies with a published comparison (<sup>[24](#ref-ZTV+14)</sup> and<sup>[27](#ref-YDS+21)</sup>), our per-study test AUC is very high (0.98–1.00),
but it drops to 0.73 on a third dataset where the literature value is 0.85<sup>[25](#ref-BRRS16)</sup>.
For holdout studies with published AUC values (<sup>[31](#ref-BWY+23)</sup>,<sup>[33](#ref-CAB+24)</sup>,<sup>[36](#ref-GYX+25)</sup>), our AUC (0.66–0.68) is consistently lower than the literature (0.86–0.88).
The literature numbers come from within-study cross-validation or test splits rather than independent cohorts
and are therefore not directly comparable to true holdout performance.

<table>
<caption>Table 9: Per-study cancer diagnosis AUC from the best tetramer
UC/CAP classifier selected in Table 6 (SVM, feature set 5). AUC is
computed over each study’s test-split runs (development) or all runs
(holdout); the <em>n</em> column reports the total number of samples
(cancer + healthy) contributing to each per-study AUC. Literature AUC
values for colorectal cancer are shown where reported.</caption>
<thead>
<tr>
<th rowspan="2">Partition</th>
<th colspan="3">Breast cancer</th>
<th colspan="4">Colorectal cancer</th>
</tr>
<tr>
<th>Dataset</th>
<th><em>n</em></th>
<th>AUC</th>
<th>Dataset</th>
<th><em>n</em></th>
<th>AUC</th>
<th>AUC (literature)</th>
</tr>
</thead>
<tbody>
<tr>
<td>Development</td>
<td><span class="citation" data-cites="AAM+13"><sup><a
href="#ref-AAM+13" role="doc-biblioref">11</a></sup></span></td>
<td>9</td>
<td>0.21</td>
<td><span class="citation" data-cites="ZTV+14"><sup><a
href="#ref-ZTV+14" role="doc-biblioref">24</a></sup></span></td>
<td>23</td>
<td>0.98</td>
<td>0.84</td>
</tr>
<tr>
<td>Development</td>
<td><span class="citation" data-cites="GJH+15"><sup><a
href="#ref-GJH+15" role="doc-biblioref">12</a></sup></span></td>
<td>19</td>
<td>0.72</td>
<td><span class="citation" data-cites="BRRS16"><sup><a
href="#ref-BRRS16" role="doc-biblioref">25</a></sup></span></td>
<td>31</td>
<td>0.73</td>
<td>0.85</td>
</tr>
<tr>
<td>Development</td>
<td><span class="citation" data-cites="GHB+18"><sup><a
href="#ref-GHB+18" role="doc-biblioref">13</a></sup></span></td>
<td>20</td>
<td>0.62</td>
<td><span class="citation" data-cites="OKN+21"><sup><a
href="#ref-OKN+21" role="doc-biblioref">26</a></sup></span></td>
<td>23</td>
<td>0.35</td>
<td>—</td>
</tr>
<tr>
<td>Development</td>
<td><span class="citation" data-cites="BVW+21"><sup><a
href="#ref-BVW+21" role="doc-biblioref">14</a></sup></span></td>
<td>29</td>
<td>0.71</td>
<td><span class="citation" data-cites="YDS+21"><sup><a
href="#ref-YDS+21" role="doc-biblioref">27</a></sup></span></td>
<td>18</td>
<td>1.00</td>
<td>0.87</td>
</tr>
<tr>
<td>Development</td>
<td><span class="citation" data-cites="BSR+22"><sup><a
href="#ref-BSR+22" role="doc-biblioref">15</a></sup></span></td>
<td>7</td>
<td>0.60</td>
<td><span class="citation" data-cites="YWS+21"><sup><a
href="#ref-YWS+21" role="doc-biblioref">28</a></sup></span></td>
<td>20</td>
<td>0.92</td>
<td>—</td>
</tr>
<tr>
<td>Development</td>
<td><span class="citation" data-cites="WZK+22"><sup><a
href="#ref-WZK+22" role="doc-biblioref">16</a></sup></span></td>
<td>15</td>
<td>0.52</td>
<td><span class="citation" data-cites="DLT+22"><sup><a
href="#ref-DLT+22" role="doc-biblioref">29</a></sup></span></td>
<td>16</td>
<td>0.78</td>
<td>—</td>
</tr>
<tr>
<td>Development</td>
<td><span class="citation" data-cites="ZZZ+22"><sup><a
href="#ref-ZZZ+22" role="doc-biblioref">17</a></sup></span></td>
<td>8</td>
<td>1.00</td>
<td><span class="citation" data-cites="PCL+22"><sup><a
href="#ref-PCL+22" role="doc-biblioref">30</a></sup></span></td>
<td>10</td>
<td>0.88</td>
<td>—</td>
</tr>
<tr>
<td>Holdout</td>
<td><span class="citation" data-cites="SKC+23"><sup><a
href="#ref-SKC+23" role="doc-biblioref">18</a></sup></span></td>
<td>43</td>
<td>0.58</td>
<td><span class="citation" data-cites="BWY+23"><sup><a
href="#ref-BWY+23" role="doc-biblioref">31</a></sup></span></td>
<td>89</td>
<td>0.66</td>
<td>0.86</td>
</tr>
<tr>
<td>Holdout</td>
<td><span class="citation" data-cites="LBA+25"><sup><a
href="#ref-LBA+25" role="doc-biblioref">19</a></sup></span></td>
<td>92</td>
<td>0.51</td>
<td><span class="citation" data-cites="BRR+24"><sup><a
href="#ref-BRR+24" role="doc-biblioref">32</a></sup></span></td>
<td>102</td>
<td>0.61</td>
<td>—</td>
</tr>
<tr>
<td>Holdout</td>
<td><span class="citation" data-cites="SYL+25"><sup><a
href="#ref-SYL+25" role="doc-biblioref">20</a></sup></span></td>
<td>20</td>
<td>0.50</td>
<td><span class="citation" data-cites="CAB+24"><sup><a
href="#ref-CAB+24" role="doc-biblioref">33</a></sup></span></td>
<td>120</td>
<td>0.68</td>
<td>0.86</td>
</tr>
<tr>
<td>Holdout</td>
<td><span class="citation" data-cites="MTK+26"><sup><a
href="#ref-MTK+26" role="doc-biblioref">21</a></sup></span></td>
<td>64</td>
<td>0.47</td>
<td><span class="citation" data-cites="SGH+24"><sup><a
href="#ref-SGH+24" role="doc-biblioref">34</a></sup></span></td>
<td>20</td>
<td>0.52</td>
<td>—</td>
</tr>
<tr>
<td>Holdout</td>
<td><span class="citation" data-cites="SVK+26"><sup><a
href="#ref-SVK+26" role="doc-biblioref">22</a></sup></span></td>
<td>52</td>
<td>0.68</td>
<td><span class="citation" data-cites="ARF+25"><sup><a
href="#ref-ARF+25" role="doc-biblioref">35</a></sup></span></td>
<td>40</td>
<td>0.70</td>
<td>—</td>
</tr>
<tr>
<td>Holdout</td>
<td><span class="citation" data-cites="YTK+26"><sup><a
href="#ref-YTK+26" role="doc-biblioref">23</a></sup></span></td>
<td>30</td>
<td>0.69</td>
<td><span class="citation" data-cites="GYX+25"><sup><a
href="#ref-GYX+25" role="doc-biblioref">36</a></sup></span></td>
<td>131</td>
<td>0.68</td>
<td>0.88</td>
</tr>
</tbody>
</table>

We did not find direct AUC comparisons in the literature for the breast cancer datasets we used, but some comparable results exist.
Daga and Oudah<sup>[37](#ref-DO24)</sup> reported a peak within-cohort AUC of 0.83 for breast cancer with Bernoulli Naïve Bayes.
Our in-study test AUCs for breast cancer diagnosis are all lower than this except for one dataset.
Wang et al.<sup>[38](#ref-WYH+22)</sup> trained random forest classifiers on fecal microbiome data from breast cancer patients and healthy controls, achieving cross-cohort
AUCs of 0.65–0.66, which sits toward the upper end of our per-study holdout values for breast cancer (0.47–0.69 Table 9).

Interestingly, the test AUCs for breast cancer are generally lower than those for colorectal cancer datasets (Table 9).
This pattern extends to the holdout studies - for breast cancer only 2 out of 6 holdout studies have AUC \> 0.6,
while for colorectal cancer this improves to 5 out of 6 studies.
This indicates easier detection of colorectal cancer than breast cancer for models simultaneously trained on data from both cancer types.

Comparing holdout performance across Tables 4 and 6, UC/CAP offers a consistent advantage over run-level tetramer features for cancer type.
However, it barely improves holdout AUC for cancer diagnosis despite a large increase on in-study test splits.
This suggests that the compositional diversity captured by cluster abundance profiles
partially breaks the study-level shortcuts that hinder tetramer-based cancer type classifiers,
while transferable signal for discriminating cancer from healthy may not reside in fine-scale within-run compositional structure.

### HyenaDNA versus SetBERT

Both deep-learning models underperform the best classical methods on holdout data.
Comparing Tables 7 and 8, the two models produce nearly identical holdout AUC for cancer diagnosis
(best: 0.57 for HyenaDNA linear, 0.56 for SetBERT MLP).
For cancer type, SetBERT achieves higher test AUC (0.98 versus 0.89 for HyenaDNA)
but HyenaDNA generalizes better to holdout studies (best: 0.79 MLP versus 0.70 cosine for SetBERT).
HyenaDNA’s stronger holdout AUC on cancer type is notable given that it was pre-trained on the human genome rather than on microbial sequences;
the domain mismatch does not appear to be the limiting factor.

At 16k positions per set and 5 sets per run, the number of sequences per sample seen by HyenaDNA is 323 ± 112 (min 50 for ref<sup>[23](#ref-YTK+26)</sup>, max 540 for ref<sup>[14](#ref-BVW+21)</sup>).
This is comparable to the 350 sequences per run used for SetBERT
Although this is a fraction of what the tetramer and UC/CAP methods use (up to 5,000),
our set-size ablations do not support set size as the limiting factor (Figure 3).

The aggregated representation in HyenaDNA before classification may contribute to the lower AUC relative to classical methods.
SetBERT is an interesting alternative as it uses set attention blocks so embeddings are affected by sample context (i.e. other sequences).
In our experiments, SetBERT performs better than HyenaDNA on in-study test splits but not on holdout datasets.
A possible contributing factor is that SetBERT sequence processing takes only 150 bp from each sequence,
which may lose information useful for generalizing to unseen studies.
Also, SetBERT was pre-trained on V3-V4 regions on 16S rRNA, while some of our holdout studies use different regions.

### Directions for improvement

Table 9 reveals substantial variation in per-study AUC for cancer diagnosis.
Most values exceed 0.5, meaning the model makes better-than-random predictions for the majority of datasets.
Where AUC falls below 0.5, the model is systematically wrong.
This range of difficulty is visible only because the benchmark aggregates many studies;
a single-study or small-scale evaluation would likely miss it.
Targeting the most challenging studies for model improvement, for example, by up-weighting hard examples during training,
could be a productive direction for future work.

Several avenues may improve holdout performance.
UC/CAP parameters (*K*, *n*<sub>CAP</sub>) could be tuned jointly with the classifier rather than selected independently.
Soft cluster assignments (Gaussian mixture or fuzzy *k*-means) might better capture the continuous composition of microbial communities.
For both deep-learning models, additional pre-training on 16S rRNA sequences would better align their representations with the target domain.

More broadly, our results reinforce a general lesson for machine learning in genomics and microbiome research:
metrics from within-study test splits can be misleading by a wide margin.
Evaluation against temporally and geographically diverse holdout cohorts should be a standard requirement<sup>[6](#ref-WSNP22)</sup>.

### Limitations

Several limitations should be noted.
First, the cancer-type task combines female-only datasets (breast cancer) with datasets of mixed sex (colorectal cancer).
Sex-specific differences in fecal microbiome composition are known<sup>[39](#ref-GVR25)</sup> and could confound this comparison,
because a model may learn to distinguish female from mixed-sex samples rather than breast from colorectal cancer.
Filtering colorectal cancer datasets to include only female participants would address this,
but is feasible only where participant sex metadata are available.

Second, study-level confounders, including primer choice, sequencing platform, and geographic region,
are unavoidable in a multi-study benchmark and limit how cleanly the signal can be attributed to cancer biology.

Third, both deep-learning models were fine-tuned with a small number of sequences per run (about 323–350) relative to the full sequencing depth of many runs.
Strategies that use more sequences, such as multi-instance learning or set-level ensembling with larger sets, could better exploit available data.
This idea is conditioned by our finding that increasing set length above 2k positions has a small positive (cancer diagnosis)
or large negative (cancer type) effect on holdout classification with HyenaDNA (Figure 3).

## Acknowledgments

This study uses data made available by many previous studies.
All contributors to those studies are acknowledged for making this study possible.

## Declaration of generative AI use

Cursor was used for code generation.
Cursor and Claude Sonnet 4.6 were used for writing sections of the manuscript.
Claude Sonnet 4.6 was used for polishing the text.
AI-generated text was incorporated into the manuscript after human review and cleanup by the author.

## Code and data availability

Code and data are available at <https://github.com/jedick/BreCol>.
The repository also holds the manuscript revision prompts and manuscript files with history of AI and human edits.

## References

<div id="refs" class="references csl-bib-body" entry-spacing="0" line-spacing="2" markdown="1">

<div id="ref-ZFL18" class="csl-entry" markdown="1">

<span class="csl-left-margin">1. </span><span class="csl-right-inline">Zou, S., Fang, L. & Lee, M.-H. [Dysbiosis of gut microbiota in promoting the development of colorectal cancer](https://doi.org/10.1093/gastro/gox031). *Gastroenterology Report* **6**, 1–12 (2018).</span>

</div>

<div id="ref-YTF+17" class="csl-entry" markdown="1">

<span class="csl-left-margin">2. </span><span class="csl-right-inline">Yang, J. *et al.* [Gastrointestinal microbiome and breast cancer: Correlations, mechanisms and potential clinical implications](https://doi.org/10.1007/s12282-016-0734-z). *Breast Cancer* **24**, 220–228 (2017).</span>

</div>

<div id="ref-ZXS21" class="csl-entry" markdown="1">

<span class="csl-left-margin">3. </span><span class="csl-right-inline">Zhang, J., Xia, Y. & Sun, J. [Breast and gut microbiome in health and cancer](https://doi.org/10.1016/j.gendis.2020.08.002). *Genes & Diseases* **8**, 581–589 (2021).</span>

</div>

<div id="ref-WPK+19" class="csl-entry" markdown="1">

<span class="csl-left-margin">4. </span><span class="csl-right-inline">Wirbel, J. *et al.* [Meta-analysis of fecal metagenomes reveals global microbial signatures that are specific for colorectal cancer](https://doi.org/10.1038/s41591-019-0406-6). *Nature Medicine* **25**, 679–689 (2019).</span>

</div>

<div id="ref-SHL+25" class="csl-entry" markdown="1">

<span class="csl-left-margin">5. </span><span class="csl-right-inline">Sun, Y. *et al.* [Benchmarking and optimizing microbiome-based bioinformatics workflow for non-invasive detection of intestinal tumors](https://doi.org/10.20517/mrr.2025.75). *Microbiome Research Reports* **4**, 43 (2025).</span>

</div>

<div id="ref-WSNP22" class="csl-entry" markdown="1">

<span class="csl-left-margin">6. </span><span class="csl-right-inline">Whalen, S., Schreiber, J., Noble, W. S. & Pollard, K. S. [Navigating the pitfalls of applying machine learning in genomics](https://doi.org/10.1038/s41576-021-00434-9). *Nature Reviews Genetics* **23**, 169–181 (2022).</span>

</div>

<div id="ref-DAB+09" class="csl-entry" markdown="1">

<span class="csl-left-margin">7. </span><span class="csl-right-inline">Dick, G. J. *et al.* [Community-wide analysis of microbial genome sequence signatures](https://doi.org/10.1186/gb-2009-10-8-r85). *Genome Biology* **10**, R85 (2009).</span>

</div>

<div id="ref-Bok25" class="csl-entry" markdown="1">

<span class="csl-left-margin">8. </span><span class="csl-right-inline">Bokulich, N. A. [Integrating sequence composition information into microbial diversity analyses with k-mer frequency counting](https://doi.org/10.1128/msystems.01550-24). *mSystems* **10**, e01550–24 (2025).</span>

</div>

<div id="ref-NPF+23" class="csl-entry" markdown="1">

<span class="csl-left-margin">9. </span><span class="csl-right-inline">Nguyen, E. *et al.* [HyenaDNA: Long-range genomic sequence modeling at single nucleotide resolution](https://proceedings.neurips.cc/paper_files/paper/2023/file/86ab6927ee4ae9bde4247793c46797c7-Paper-Conference.pdf). in *Advances in neural information processing systems* (eds Oh, A. et al.) vol. 36 43177–43201 (Curran Associates, Inc., 2023).</span>

</div>

<div id="ref-LGA+25" class="csl-entry" markdown="1">

<span class="csl-left-margin">10. </span><span class="csl-right-inline">Ludwig, I., David W *et al.* [SetBERT: The deep learning platform for contextualized embeddings and explainable predictions from high-throughput sequencing](https://doi.org/10.1093/bioinformatics/btaf370). *Bioinformatics* **41**, btaf370 (2025).</span>

</div>

<div id="ref-AAM+13" class="csl-entry" markdown="1">

<span class="csl-left-margin">11. </span><span class="csl-right-inline">Attraplsi, S., Abbasi, R., Mohammed Abdul, M. K., Salih, M. & Mutlu, E. [Fecal microbiota composition in women in relation to factors that may impact breast cancer development: 625](https://doi.org/10.14309/00000434-201310001-00625). *American Journal of Gastroenterology* **108**, S183 (2013).</span>

</div>

<div id="ref-GJH+15" class="csl-entry" markdown="1">

<span class="csl-left-margin">12. </span><span class="csl-right-inline">Goedert, J. J. *et al.* [Investigation of the association between the fecal microbiota and breast cancer in postmenopausal women: A population-based case-control pilot study](https://doi.org/10.1093/jnci/djv147). *Journal of the National Cancer Institute* **107**, djv147 (2015).</span>

</div>

<div id="ref-GHB+18" class="csl-entry" markdown="1">

<span class="csl-left-margin">13. </span><span class="csl-right-inline">Goedert, J. J. *et al.* [Postmenopausal breast cancer and oestrogen associations with the IgA-coated and IgA-noncoated faecal microbiota](https://doi.org/10.1038/bjc.2017.435). *British Journal of Cancer* **118**, 471–479 (2018).</span>

</div>

<div id="ref-BVW+21" class="csl-entry" markdown="1">

<span class="csl-left-margin">14. </span><span class="csl-right-inline">Byrd, D. A. *et al.* [Associations of fecal microbial profiles with breast cancer and nonmalignant breast disease in the Ghana Breast Health Study](https://doi.org/10.1002/ijc.33473). *International Journal of Cancer* **148**, 2712–2723 (2021).</span>

</div>

<div id="ref-BSR+22" class="csl-entry" markdown="1">

<span class="csl-left-margin">15. </span><span class="csl-right-inline">Bilenduke, E. *et al.* [Impacts of breast cancer and chemotherapy on gut microbiome, cognitive functioning, and mood relative to healthy controls](https://doi.org/10.1038/s41598-022-23793-7). *Scientific Reports* **12**, 19547 (2022).</span>

</div>

<div id="ref-WZK+22" class="csl-entry" markdown="1">

<span class="csl-left-margin">16. </span><span class="csl-right-inline">Wenhui, Y. *et al.* [Variations in the gut microbiota in breast cancer occurrence and bone metastasis](https://doi.org/10.3389/fmicb.2022.894283). *Frontiers in Microbiology* **13**, 894283 (2022).</span>

</div>

<div id="ref-ZZZ+22" class="csl-entry" markdown="1">

<span class="csl-left-margin">17. </span><span class="csl-right-inline">Zhu, Q. *et al.* [L‐norvaline affects the proliferation of breast cancer cells based on the microbiome and metabolome analysis](https://doi.org/10.1111/jam.15620). *Journal of Applied Microbiology* **133**, 1014–1026 (2022).</span>

</div>

<div id="ref-SKC+23" class="csl-entry" markdown="1">

<span class="csl-left-margin">18. </span><span class="csl-right-inline">Shrode, R. L. *et al.* [Breast cancer patients from the Midwest region of the United States have reduced levels of short-chain fatty acid-producing gut bacteria](https://doi.org/10.1038/s41598-023-27436-3). *Scientific Reports* **13**, 526 (2023).</span>

</div>

<div id="ref-LBA+25" class="csl-entry" markdown="1">

<span class="csl-left-margin">19. </span><span class="csl-right-inline">Laborda-Illanes, A. *et al.* [Exploring the interplay between gut microbiota and the melatonergic pathway in hormone receptor-positive breast cancer](https://doi.org/10.3390/ijms26146801). *International Journal of Molecular Sciences* **26**, 6801 (2025).</span>

</div>

<div id="ref-SYL+25" class="csl-entry" markdown="1">

<span class="csl-left-margin">20. </span><span class="csl-right-inline">Sheikh, T. M. M. *et al.* [Integrated insights into gut microbiota and metabolomic landscape in breast cancer patients undergoing adjuvant endocrine therapy](https://doi.org/10.1128/msystems.00879-25). *mSystems* **10**, e00879–25 (2025).</span>

</div>

<div id="ref-MTK+26" class="csl-entry" markdown="1">

<span class="csl-left-margin">21. </span><span class="csl-right-inline">Mahno, N. E., Tay, D. D., Khalid, N. S., Termizi, S. A. & Ahmad, H. F. [Multi-kingdom gut microbiome features associated with breast cancer and menopausal status](https://doi.org/10.1016/j.gutmic.2026.100009). *Gut Microbiology* **2**, 100009 (2026).</span>

</div>

<div id="ref-SVK+26" class="csl-entry" markdown="1">

<span class="csl-left-margin">22. </span><span class="csl-right-inline">Seenivasan, S. N. *et al.* Unique gut microbiome signature with expression of microbial oncogenes among Indian breast cancer patients. *Research Square* <https://doi.org/10.21203/rs.3.rs-8921895/v1> (2026) doi:[10.21203/rs.3.rs-8921895/v1](https://doi.org/10.21203/rs.3.rs-8921895/v1).</span>

</div>

<div id="ref-YTK+26" class="csl-entry" markdown="1">

<span class="csl-left-margin">23. </span><span class="csl-right-inline">Yerlikaya, F. H. *et al.* [Changes in microbiota and short-chain fatty acids, lipopolysaccharide-binding protein and zonulin in people with breast cancer](https://doi.org/10.1007/s44411-026-00523-3). *Bratislava Medical Journal* **127**, 1604–1620 (2026).</span>

</div>

<div id="ref-ZTV+14" class="csl-entry" markdown="1">

<span class="csl-left-margin">24. </span><span class="csl-right-inline">Zeller, G. *et al.* [Potential of fecal microbiota for early-stage detection of colorectal cancer](https://doi.org/10.15252/msb.20145645). *Molecular Systems Biology* **10**, 766 (2014).</span>

</div>

<div id="ref-BRRS16" class="csl-entry" markdown="1">

<span class="csl-left-margin">25. </span><span class="csl-right-inline">Baxter, N. T., Ruffin, M. T., Rogers, M. A. M. & Schloss, P. D. [Microbiota-based model improves the sensitivity of fecal immunochemical test for detecting colonic lesions](https://doi.org/10.1186/s13073-016-0290-3). *Genome Medicine* **8**, 37 (2016).</span>

</div>

<div id="ref-OKN+21" class="csl-entry" markdown="1">

<span class="csl-left-margin">26. </span><span class="csl-right-inline">Okumura, S. *et al.* [Gut bacteria identified in colorectal cancer patients promote tumourigenesis via butyrate secretion](https://doi.org/10.1038/s41467-021-25965-x). *Nature Communications* **12**, 5674 (2021).</span>

</div>

<div id="ref-YDS+21" class="csl-entry" markdown="1">

<span class="csl-left-margin">27. </span><span class="csl-right-inline">Yang, Y. *et al.* [Dysbiosis of human gut microbiome in young-onset colorectal cancer](https://doi.org/10.1038/s41467-021-27112-y). *Nature Communications* **12**, 6757 (2021).</span>

</div>

<div id="ref-YWS+21" class="csl-entry" markdown="1">

<span class="csl-left-margin">28. </span><span class="csl-right-inline">Young, C. *et al.* [The colorectal cancer-associated faecal microbiome of developing countries resembles that of developed countries](https://doi.org/10.1186/s13073-021-00844-8). *Genome Medicine* **13**, 27 (2021).</span>

</div>

<div id="ref-DLT+22" class="csl-entry" markdown="1">

<span class="csl-left-margin">29. </span><span class="csl-right-inline">Du, X. *et al.* [Alterations of the gut microbiome and fecal metabolome in colorectal cancer: Implication of intestinal metabolism for tumorigenesis](https://doi.org/10.3389/fphys.2022.854545). *Frontiers in Physiology* **13**, 854545 (2022).</span>

</div>

<div id="ref-PCL+22" class="csl-entry" markdown="1">

<span class="csl-left-margin">30. </span><span class="csl-right-inline">Png, C.-W., Chua, Y.-K., Law, J.-H., Zhang, Y. & Tan, K.-K. [Alterations in co-abundant bacteriome in colorectal cancer and its persistence after surgery: A pilot study](https://doi.org/10.1038/s41598-022-14203-z). *Scientific Reports* **12**, 9829 (2022).</span>

</div>

<div id="ref-BWY+23" class="csl-entry" markdown="1">

<span class="csl-left-margin">31. </span><span class="csl-right-inline">Bose, M. *et al.* [Analysis of an Indian colorectal cancer faecal microbiome collection demonstrates universal colorectal cancer-associated patterns, but closest correlation with other Indian cohorts](https://doi.org/10.1186/s12866-023-02805-0). *BMC Microbiology* **23**, 52 (2023).</span>

</div>

<div id="ref-BRR+24" class="csl-entry" markdown="1">

<span class="csl-left-margin">32. </span><span class="csl-right-inline">Bars-Cortina, D. *et al.* [Comparison between <span class="nocase">16S rRNA</span> and shotgun sequencing in colorectal cancer, advanced colorectal lesions, and healthy human gut microbiota](https://doi.org/10.1186/s12864-024-10621-7). *BMC Genomics* **25**, 730 (2024).</span>

</div>

<div id="ref-CAB+24" class="csl-entry" markdown="1">

<span class="csl-left-margin">33. </span><span class="csl-right-inline">Conde-Pérez, K. *et al.* [The multispecies microbial cluster of Fusobacterium, Parvimonas, Bacteroides and Faecalibacterium as a precision biomarker for colorectal cancer diagnosis](https://doi.org/10.1002/1878-0261.13604). *Molecular Oncology* **18**, 1093–1122 (2024).</span>

</div>

<div id="ref-SGH+24" class="csl-entry" markdown="1">

<span class="csl-left-margin">34. </span><span class="csl-right-inline">Shastry, R. P. *et al.* [Emergence of rare and low abundant anaerobic gut Firmicutes is associated with a significant downfall of Klebsiella in human colon cancer](https://doi.org/10.1016/j.micpath.2024.106726). *Microbial Pathogenesis* **193**, 106726 (2024).</span>

</div>

<div id="ref-ARF+25" class="csl-entry" markdown="1">

<span class="csl-left-margin">35. </span><span class="csl-right-inline">Ashraf, H. *et al.* [On exploring cross-sectional stability and persistence of microbiome in a multiple body site colorectal cancer dataset](https://doi.org/10.3389/fmicb.2025.1449642). *Frontiers in Microbiology* **16**, 1449642 (2025).</span>

</div>

<div id="ref-GYX+25" class="csl-entry" markdown="1">

<span class="csl-left-margin">36. </span><span class="csl-right-inline">Guodong, W. *et al.* [Fecal occult blood affects intestinal microbial community structure in colorectal cancer](https://doi.org/10.1186/s12866-024-03721-7). *BMC Microbiology* **25**, 34 (2025).</span>

</div>

<div id="ref-DO24" class="csl-entry" markdown="1">

<span class="csl-left-margin">37. </span><span class="csl-right-inline">Daga, P. & Oudah, M. Machine learning and gut microbiome for breast cancer screening. in *2024 IEEE conference on computational intelligence in bioinformatics and computational biology (CIBCB)* 1–7 (2024). doi:[10.1109/CIBCB58642.2024.10702110](https://doi.org/10.1109/CIBCB58642.2024.10702110).</span>

</div>

<div id="ref-WYH+22" class="csl-entry" markdown="1">

<span class="csl-left-margin">38. </span><span class="csl-right-inline">Wang, N. *et al.* [Identifying distinctive tissue and fecal microbial signatures and the tumor-promoting effects of deoxycholic acid on breast cancer](https://doi.org/10.3389/fcimb.2022.1029905). *Frontiers in Cellular and Infection Microbiology* **12**, 1029905 (2022).</span>

</div>

<div id="ref-GVR25" class="csl-entry" markdown="1">

<span class="csl-left-margin">39. </span><span class="csl-right-inline">Ghaffar, T., Valeriani, F. & Romano Spica, V. [The sex related differences in health and disease: A systematic review of sex-specific gut microbiota and possible implications for microbial pathogenesis](https://doi.org/10.1016/j.micpath.2025.108094). *Microbial Pathogenesis* **209**, 108094 (2025).</span>

</div>

</div>

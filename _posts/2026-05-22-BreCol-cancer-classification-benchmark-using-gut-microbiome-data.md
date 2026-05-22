---
title: "BreCol: Cancer classification benchmark using gut microbiome data"
date: 2026-05-22
last_modified_at: 2026-05-22
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
We train four classifier pipelines: classical (tetramer counts aggregated to run-level frequencies or
unsupervised clustering with cluster abundance profiles (UC/CAP)), deep learning (HyenaDNA sequence modeling with mean-pooled
token representations of packed contexts), and hybrid (sequence-level HyenaDNA embeddings with UC/CAP profiles).
Among classical methods, UC/CAP achieves the strongest holdout performance (AUC 0.84 for cancer type with KNN, 0.61 for cancer diagnosis with SVM).
The differential between test (in-study) and holdout AUC is 0.15 points for both cancer diagnosis and cancer type prediction
for the best classical classifier, confirming that conventional evaluation inflates apparent model skill.
A pure deep-learning pipeline with HyenaDNA achieves relatively poor results, perhaps because the mean-pooled token representation
before the classification layer discards within-run compositional structure.
Finally, a hybrid architecture combining HyenaDNA’s embeddings with cluster abundance profiles achieves comparable
results to the parallel all-classical pipeline with tetramer features.
Our benchmark and associated code are publicly available to support reproducible, credible evaluation of microbiome-based cancer classifiers.

## Introduction

The community of microorganisms inhabiting the human digestive tract, known as the gut microbiome, is increasingly linked to cancer risk and progression.
Large-scale epidemiological and mechanistic studies have associated compositional shifts in gut bacteria with colorectal cancer (CRC),
and growing evidence implicates gut dysbiosis in breast cancer as well.
Machine learning models trained on microbiome profiles have shown promise for distinguishing cancer patients from healthy controls within individual cohorts,
raising the prospect of non-invasive, microbiome-based cancer screening<sup>[1](#ref-WPK+19),[2](#ref-SHL+25)</sup>.

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
regional microbiome variation introduce large study-level signals that a model can exploit without learning any biology<sup>[3](#ref-WSNP22)</sup>.
As a specific example, Sun et al.<sup>[2](#ref-SHL+25)</sup> found lower AUC for leave-one-dataset-out (LODO) than for cross-validation (CV)
in CRC prediction from 16S-based taxonomic profiles (average AUC for CV: 0.82, LODO: 0.77).

This problem is exacerbated for cancer type prediction (a different task from cancer vs healthy prediction).
Breast and colorectal cancer samples almost always come from entirely separate studies,
so a classifier can achieve near-perfect in-study accuracy simply by identifying the study of origin rather than the disease.
Evaluating such a model on test samples from the same studies dramatically overestimates generalization.
A reliable benchmark must therefore evaluate models on holdout studies, i.e. studies never encountered during training<sup>[3](#ref-WSNP22)</sup>.

We address this directly. We curate a compilation of 2,040 16S rRNA sequencing runs spanning 26 studies (13 breast cancer, 13 colorectal cancer),
covering healthy controls and two cancer types across studies from 2013 to 2026.
Studies are partitioned chronologically: the first seven studies per cancer type form the development set (training, validation, and test),
while the more recent six studies per cancer type are reserved as an external holdout.
The temporal and study-level separation in this benchmark provides a demanding but credible measure of real-world generalizability.

Against this benchmark we evaluate a progression of approaches.
For classical machine learning we begin with run-level tetramer frequencies.
First, the 256 possible DNA tetramers are counted in each 16S sequence and aggregated to relative frequencies for each sequencing run.
We then introduce unsupervised clustering with cluster abundance profiles (UC/CAP).
In contrast to run-level aggregation, UC/CAP preserves within-run compositional structure by creating sequence clusters that share similar tetramer counts,
then profiling the cluster affiliation of a large number of sequences from each run.
This method is analogous in purpose to operational taxonomic unit (OTU)-based approaches but is reference-free;
that is, it operates entirely on sequence composition without taxonomic assignment.

For deep learning we use HyenaDNA<sup>[4](#ref-NPF+23)</sup>, a long-range genomic sequence model pretrained on the human reference genome.
We first train a multilayer perceptron (MLP) classification head on top of a mean-pooled token representation.
Because this pooled representation collapses all sequences in a packed context into a single vector,
it cannot capture within-run compositional structure (a similar limitation to run-level aggregation of tetramer frequencies).
Therefore, our final classification pipeline is a hybrid that uses fixed embeddings from the pretrained HyenaDNA model.
These embeddings are retrieved for each sequence then used as the feature store for UC/CAP processing and downstream classification.

Our main contributions are (1) a rigorously curated, temporally structured multi-study benchmark for microbiome-based cancer classification
that provides more reliable estimates of real-world performance than within-study splits,
and (2) a cluster abundance profile method that shows consistent gains on multitask performance
and that can be applied to both classical features and embeddings from pretrained language models.

## Methods

### Data curation

Each sample corresponds to a sequencing run containing multiple 16S rRNA gene sequences.
We collected sequencing runs from studies covering breast cancer and colorectal cancer;
studies were only included if both cancer-positive and healthy control labels were available.
We stored SRA Run accessions (beginning with SRR, ERR, or DRR) and study metadata in the repository and downloaded each run’s read archive from NCBI.

Our compilation spans 26 studies in total—13 for breast cancer and 13 for colorectal cancer (Table 1).
Arranged chronologically by publication year, the first seven studies per cancer type form the development partition
(train, validation, and test splits), and the more recent six studies per cancer type are reserved as the holdout partition.
Development and holdout sets are separated not only by study boundaries but also by time: all holdout studies are from 2023 onward.
This design makes the benchmark a realistic challenge: predictions must transfer to future datasets available only after the model was trained.

<table>
<caption>Table 1: Breast and colorectal cancer studies included in the
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
href="#ref-AAM+13" role="doc-biblioref">5</a></sup></span></td>
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
href="#ref-GJH+15" role="doc-biblioref">6</a></sup></span></td>
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
href="#ref-GHB+18" role="doc-biblioref">7</a></sup></span></td>
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
href="#ref-BVW+21" role="doc-biblioref">8</a></sup></span></td>
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
href="#ref-BSR+22" role="doc-biblioref">9</a></sup></span></td>
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
href="#ref-WZK+22" role="doc-biblioref">10</a></sup></span></td>
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
href="#ref-ZZZ+22" role="doc-biblioref">11</a></sup></span></td>
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
href="#ref-SKC+23" role="doc-biblioref">12</a></sup></span></td>
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
href="#ref-LBA+25" role="doc-biblioref">13</a></sup></span></td>
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
href="#ref-SYL+25" role="doc-biblioref">14</a></sup></span></td>
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
href="#ref-MTK+26" role="doc-biblioref">15</a></sup></span></td>
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
href="#ref-SVK+26" role="doc-biblioref">16</a></sup></span></td>
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
href="#ref-YTK+26" role="doc-biblioref">17</a></sup></span></td>
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
href="#ref-ZTV+14" role="doc-biblioref">18</a></sup></span></td>
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
href="#ref-BRRS16" role="doc-biblioref">19</a></sup></span></td>
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
href="#ref-OKN+21" role="doc-biblioref">20</a></sup></span></td>
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
href="#ref-YDS+21" role="doc-biblioref">21</a></sup></span></td>
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
href="#ref-YWS+21" role="doc-biblioref">22</a></sup></span></td>
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
href="#ref-DLT+22" role="doc-biblioref">23</a></sup></span></td>
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
href="#ref-PCL+22" role="doc-biblioref">24</a></sup></span></td>
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
href="#ref-BWY+23" role="doc-biblioref">25</a></sup></span></td>
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
href="#ref-BRR+24" role="doc-biblioref">26</a></sup></span></td>
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
href="#ref-CAB+24" role="doc-biblioref">27</a></sup></span></td>
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
href="#ref-SGH+24" role="doc-biblioref">28</a></sup></span></td>
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
href="#ref-ARF+25" role="doc-biblioref">29</a></sup></span></td>
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
href="#ref-GYX+25" role="doc-biblioref">30</a></sup></span></td>
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
The sample sizes in Table 1 reflect counts after sampling at the indicated rate; these samples are flagged as `sample_used=TRUE` in the data CSV files.
Additionally, for two studies (<sup>[8](#ref-BVW+21)</sup> and<sup>[27](#ref-CAB+24)</sup>) we excluded runs with \<2000 spots.

### Preprocessing, splits, and sampling

We normalized sample labels to a restricted vocabulary: healthy, breast cancer, and colorectal cancer.
Breast cancer samples include invasive tumors; colorectal cancer samples include carcinoma.
Any benign samples (e.g. adenomas, benign colon polyps, and breast ductal carcinoma in situ (DCIS))
and non-fecal samples in the studies were excluded from our analysis.

Among development studies, we assigned each sequencing run to stratified training, validation, or test sets in a 70:15:15 ratio.
Runs from holdout studies were excluded from this assignment.
Split assignments were defined in advance from study lists and per-study sample tables, independent of any downstream feature computation.

We held the validation set fixed (no cross-validation).
This allows the same development splits to be used consistently across both the classical and HyenaDNA pipelines,
since GPU-intensive language model training makes repeated cross-validation expensive.
The same run-level split underlies both classification tasks: cancer versus healthy (cancer diagnosis) on all samples,
and breast versus colorectal (cancer type) restricted to cancer-positive samples.

For all classification pipelines we dropped the first 1000 sequences in each run as a QC measure.
We then randomly sampled 5000 sequences from the remaining sequences in each run (or used sequence sets packed to a maximum length for HyenaDNA training).
These sequences were used to create caches of sequence-level tetramer counts, embeddings, and tensors
that were sliced into for rapid experimentation with different sample sizes used for training.

### Run-level tetramer frequencies and classification pipeline

We calculated tetramer frequencies for each run by counting all 4-mers within each sequence,
summing counts over all sequences in the run, then converting to relative frequencies, yielding a 256-dimensional feature vector per run.

For the majority-class baseline, we predict the most frequent class in the training set for all samples.

#### Hyperparameter grid search

Table 2 lists the hyperparameter values used for grid search.

<table>
<caption>Table 2: Classifier models and hyperparameter grids used in
run-level tetramer frequency classification and in UC/CAP classification
for both tetramer counts and HyenaDNA embeddings.</caption>
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

### HyenaDNA sequence modeling and classification

We trained HyenaDNA on 16S RNA sequence data to test an end-to-end sequence model.
For each run, we read the FASTA file and split its sequences into a fixed number of non-overlapping sets.
Each set was packed to the model length limit and tokenized at the DNA character level.

We initialized HyenaDNA from pretrained weights, using a multitask configuration (two MLP classification heads attached to the same backbone).
In each forward pass, the cross-entropy loss for each task was computed separately and combined with equal weight.
Because each run can produce multiple sequence sets, training loss was computed across all valid sets for each run.
At evaluation, we averaged set-level logits to obtain one prediction per run,
then computed AUC on the same test and holdout splits used for the tetramer and UC/CAP analyses.

Head pooling mode was set to mean pooling, the model was trained for 10 epochs, and batch size was adjusted to maximize GPU memory utilization.
Other hyperparameters (maximum length of sequence sets, learning rate, MLP size and dropout, and backbone unfreezing) were used for ablations.

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

### Cluster abundance profiles for HyenaDNA embeddings

Our fourth classification pipeline does not perform any training of HyenaDNA but uses the pretrained 32k model to generate embeddings.
These 256-dimensional vectors were generated for sampled sequences in each run and used to produce UC/CAP profiles just like we did for tetramer counts.
Since embeddings can have negative values, they were standardized directly (skipping the CLR transform used for tetramer features) before PCA.

The four classification pipelines used here are shown in Figure 1.
HyenaDNA sequence modeling uses a classification head that mean-pools backbone hidden states over all token positions of a packed sequence context.
This aggregation step makes it similar to using run-level tetramer frequencies for classification.
In contrast, tetramer counts and HyenaDNA embeddings are raw sequence-level features that can both be used to build UC/CAP profiles that preserve compositional trends.
The difference is that tetramer counts are an “engineered” feature, while embeddings are learned by the pretrained model (in the case of HyenaDNA, on the human genome).

<figure>
<img src="/assets/images/2026-05-22-BreCol-cancer-classification-benchmark-using-gut-microbiome-data/figure1_pipelines.svg" alt="Classification pipelines." />
<figcaption>Figure 1: Classification pipelines.</figcaption>
</figure>

Based on this picture, we propose carrying out performance comparisons at equal levels:
- At the run level: tetramer frequencies vs HyenaDNA sequence modeling
- At the sequence level: tetramer counts vs HyenaDNA pretrained embeddings (both fed into UC/CAP)

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

All models exceed the majority-class baseline on the test split, with particularly large margins for cancer type prediction (Table 3).
The holdout picture is sharply different.
For cancer diagnosis, SVM achieves a modest AUC of 0.6 while random forest and KNN fall closer to baseline.
For cancer type, SVM reaches an AUC of 0.67 while KNN collapses to baseline on holdout.
The stark contrast with test performance (AUC \>0.9) confirms that tetramer classifiers overfit to study-level signals when trained on single-study cancer-type data.

<table>
<caption>Table 3: Test and holdout AUC for run-level tetramer frequency
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
<td>0.64</td>
<td>0.56</td>
<td>0.97</td>
<td>0.49</td>
</tr>
<tr>
<td>SVM</td>
<td>0.66</td>
<td><strong>0.60</strong></td>
<td><strong>0.997</strong></td>
<td><strong>0.67</strong></td>
</tr>
<tr>
<td>Random Forest</td>
<td><strong>0.67</strong></td>
<td>0.55</td>
<td>0.99</td>
<td>0.59</td>
</tr>
</tbody>
</table>

### Classification with HyenaDNA sequence modeling

We report a fine-tuning grid for the pretrained 32k HyenaDNA model.
Given available hardware (16 GB GPU memory), we are limited to smaller model sizes and sequence budgets than the full model supports.

#### Hyperparameter ablations

We trained HyenaDNA with the ablations listed below; results are summarized in Table 4.

1.  Best recipe (baseline)
2.  High learning rate (5e-4 instead of 2e-4)
3.  Add dropout to MLP classification head (0.2)
4.  MLP hidden layer width 256 (instead of 512)
5.  Unfrozen backbone (learning rate: 2e-4)
6.  Unfrozen backbone (low learning rate: 1e-5)

<table>
<caption>Table 4: HyenaDNA fine-tuning results on the multitask 32k
model for the best recipe and targeted ablations, reported as mean ±
standard deviation across five random seeds. Epoch is the mean epoch
number with the best mean validation AUC across both tasks.</caption>
<thead>
<tr>
<th rowspan="2">Ablation</th>
<th colspan="3">Cancer diagnosis</th>
<th colspan="3">Cancer type</th>
</tr>
<tr>
<th>Epoch</th>
<th>Test</th>
<th>Holdout</th>
<th>Epoch</th>
<th>Test</th>
<th>Holdout</th>
</tr>
</thead>
<tbody>
<tr>
<td>1</td>
<td>8</td>
<td>0.53 ± 0.04</td>
<td>0.53 ± 0.01</td>
<td>8</td>
<td>0.72 ± 0.02</td>
<td>0.70 ± 0.06</td>
</tr>
<tr>
<td>2</td>
<td>7</td>
<td>0.53 ± 0.03</td>
<td>0.51 ± 0.02</td>
<td>7</td>
<td>0.74 ± 0.03</td>
<td>0.68 ± 0.05</td>
</tr>
<tr>
<td>3</td>
<td>10</td>
<td>0.55 ± 0.04</td>
<td>0.53 ± 0.01</td>
<td>10</td>
<td>0.72 ± 0.02</td>
<td>0.70 ± 0.05</td>
</tr>
<tr>
<td>4</td>
<td>5</td>
<td>0.55 ± 0.03</td>
<td>0.52 ± 0.03</td>
<td>5</td>
<td>0.73 ± 0.01</td>
<td>0.67 ± 0.03</td>
</tr>
<tr>
<td>5</td>
<td>9</td>
<td>0.59 ± 0.01</td>
<td>0.51 ± 0.00</td>
<td>9</td>
<td>0.91 ± 0.03</td>
<td>0.76 ± 0.07</td>
</tr>
<tr>
<td>6</td>
<td>9</td>
<td>0.58 ± 0.01</td>
<td>0.53 ± 0.01</td>
<td>9</td>
<td>0.94 ± 0.04</td>
<td>0.74 ± 0.07</td>
</tr>
</tbody>
</table>

Several trends are apparent in these ablations.
Increasing learning rate, adding dropout, or decreasing the MLP hidden layer width have no discernible effect on test or baseline performance within error.
The improvements on holdout associated with unfrozen backbone (most notably for cancer type) are tempered by higher variability. Lowering the learning rate in our experiments did not stabilize the predictions with full model fine-tuning.

We also verified that using float16 AMP, gradient clipping (norm 1.0), or tuning by validation F1 instead of AUC did not move holdout AUC beyond error.

#### Effects of modeled sequence length

For each task (cancer diagnosis and cancer type) we trained separate classification heads on the same backbone (multitask model).
We varied the length per set (up to 1k, 2k, 4k, 8k, 16k, and 32k positions) to study how much sequence context per run matters.
A single large cache (32k length for each sequence set) was built from randomly sampled FASTA sequences after skipping the first 1000 in each run.
Shorter training configurations were obtained from that cache by truncating to the target length.

Figure 2 shows AUC on the test and holdout splits as a function of length per set, within each task (columns).
Holdout performance is generally weaker than test performance.
The cancer diagnosis task shows mildly increasing performance with context length, but the cancer type curve is not monotone in context length.
Increasing the number of bases modeled per set does not reliably improve generalization for cancer type prediction.

<figure>
<img src="/assets/images/2026-05-22-BreCol-cancer-classification-benchmark-using-gut-microbiome-data/figure2_hyenadna.svg" alt="HyenaDNA set-length stability across tasks and number of sets." />
<figcaption>Figure 2: HyenaDNA set-length stability across tasks and number of sets.</figcaption>
</figure>

### Classification with cluster abundance profiles for tetramer counts

We explored six combinations of the three UC/CAP hyperparameters defined by *n*<sub>UC</sub> (sequences per run used for unsupervised clustering), *K* (number of clusters), and *n*<sub>CAP</sub> (sequences per run assigned to centroids and used to build cluster abundance profiles) (Table 5).

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
with the models and hyperparameter grids described above (Table 2).
SVM achieves higher holdout AUC than KNN across feature sets for cancer diagnosis, but the pattern is reversed for cancer type, where KNN leads (Figure 3).
For cancer type, both models show near-perfect in-study test performance across feature sets, but holdout values drop sharply.

<figure>
<img src="/assets/images/2026-05-22-BreCol-cancer-classification-benchmark-using-gut-microbiome-data/figure3_tetramer_uc_cap.svg" alt="Feature-set stability for UC/CAP with tetramer counts in SVM and KNN." />
<figcaption>Figure 3: Feature-set stability for UC/CAP with tetramer counts in SVM and KNN.</figcaption>
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
<td>Feature set</td>
<td colspan="2">5</td>
<td colspan="2">1</td>
</tr>
<tr>
<td>SVM</td>
<td><strong>0.76</strong></td>
<td><strong>0.61</strong></td>
<td><strong>1.00</strong></td>
<td>0.65</td>
</tr>
<tr>
<td>KNN</td>
<td>0.70</td>
<td>0.55</td>
<td>0.99</td>
<td><strong>0.84</strong></td>
</tr>
<tr>
<td>Random Forest</td>
<td>0.72</td>
<td>0.57</td>
<td>0.99</td>
<td>0.72</td>
</tr>
</tbody>
</table>

### Classification with cluster abundance profiles for HyenaDNA embeddings

We repeated the UC/CAP pipeline on sequence-level HyenaDNA embeddings (pretrained 32k model, no fine-tuning),
creating six feature sets parallel to those for tetramer counts.
Figure 4 shows holdout and test AUC across feature sets for SVM and random forest.
Holdout curves are comparatively flat: neither task shows the sharp swings seen with tetramer-based profiles in Figure 3,
suggesting that embedding CAPs are less sensitive to *K* and *n*<sub>CAP</sub> over this grid.

Using test AUC to select the best feature set for each task, we find similar holdout AUC for tetramer- and embedding-based CAPs (Tables 6 and 7).
For cancer diagnosis, SVM is the best model in both tables (holdout 0.62 with embeddings versus 0.61 with tetramers).
For cancer type, random forest leads with embeddings (0.79) while KNN leads with tetramers (0.84).

<figure>
<img src="/assets/images/2026-05-22-BreCol-cancer-classification-benchmark-using-gut-microbiome-data/figure4_embedding_uc_cap.svg" alt="Feature-set stability for UC/CAP with HyenaDNA embeddings in SVM and random forest." />
<figcaption>Figure 4: Feature-set stability for UC/CAP with HyenaDNA embeddings in SVM and random forest.</figcaption>
</figure>

<table>
<caption>Table 7: Test and holdout AUC for UC/CAP cluster abundance
profiles built from HyenaDNA embeddings (pretrained 32k model, no
fine-tuning), with the best feature set selected per task by test
AUC.</caption>
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
<td>Feature set</td>
<td colspan="2">4</td>
<td colspan="2">1</td>
</tr>
<tr>
<td>SVM</td>
<td><strong>0.74</strong></td>
<td><strong>0.62</strong></td>
<td><strong>1.00</strong></td>
<td>0.68</td>
</tr>
<tr>
<td>KNN</td>
<td>0.68</td>
<td>0.59</td>
<td>0.997</td>
<td>0.69</td>
</tr>
<tr>
<td>Random Forest</td>
<td>0.68</td>
<td>0.60</td>
<td><strong>1.00</strong></td>
<td><strong>0.79</strong></td>
</tr>
</tbody>
</table>

## Discussion

We list our per-study AUC for cancer diagnosis and comparisons with colorectal cancer where available (Table 8).
On two of the three development studies with a published comparison (<sup>[18](#ref-ZTV+14)</sup> and<sup>[21](#ref-YDS+21)</sup>), our per-study test AUC is very high (0.97–0.98),
but it drops to 0.67 on a third dataset where the literature value is 0.85<sup>[19](#ref-BRRS16)</sup>.
For holdout studies with published AUC values (<sup>[25](#ref-BWY+23)</sup>,<sup>[27](#ref-CAB+24)</sup>,<sup>[30](#ref-GYX+25)</sup>), our AUC (0.66–0.74) is consistently lower than the literature (0.86–0.88).
The literature numbers come from within-study cross-validation or test splits rather than independent cohorts
and are therefore not directly comparable to true holdout performance.

<table>
<caption>Table 8: Per-study cancer diagnosis AUC from the best tetramer
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
href="#ref-AAM+13" role="doc-biblioref">5</a></sup></span></td>
<td>7</td>
<td>0.20</td>
<td><span class="citation" data-cites="ZTV+14"><sup><a
href="#ref-ZTV+14" role="doc-biblioref">18</a></sup></span></td>
<td>18</td>
<td>0.97</td>
<td>0.84</td>
</tr>
<tr>
<td>Development</td>
<td><span class="citation" data-cites="GJH+15"><sup><a
href="#ref-GJH+15" role="doc-biblioref">6</a></sup></span></td>
<td>14</td>
<td>0.67</td>
<td><span class="citation" data-cites="BRRS16"><sup><a
href="#ref-BRRS16" role="doc-biblioref">19</a></sup></span></td>
<td>23</td>
<td>0.67</td>
<td>0.85</td>
</tr>
<tr>
<td>Development</td>
<td><span class="citation" data-cites="GHB+18"><sup><a
href="#ref-GHB+18" role="doc-biblioref">7</a></sup></span></td>
<td>17</td>
<td>0.64</td>
<td><span class="citation" data-cites="OKN+21"><sup><a
href="#ref-OKN+21" role="doc-biblioref">20</a></sup></span></td>
<td>19</td>
<td>0.58</td>
<td>—</td>
</tr>
<tr>
<td>Development</td>
<td><span class="citation" data-cites="BVW+21"><sup><a
href="#ref-BVW+21" role="doc-biblioref">8</a></sup></span></td>
<td>22</td>
<td>0.75</td>
<td><span class="citation" data-cites="YDS+21"><sup><a
href="#ref-YDS+21" role="doc-biblioref">21</a></sup></span></td>
<td>15</td>
<td>0.98</td>
<td>0.87</td>
</tr>
<tr>
<td>Development</td>
<td><span class="citation" data-cites="BSR+22"><sup><a
href="#ref-BSR+22" role="doc-biblioref">9</a></sup></span></td>
<td>5</td>
<td>1.00</td>
<td><span class="citation" data-cites="YWS+21"><sup><a
href="#ref-YWS+21" role="doc-biblioref">22</a></sup></span></td>
<td>12</td>
<td>0.83</td>
<td>—</td>
</tr>
<tr>
<td>Development</td>
<td><span class="citation" data-cites="WZK+22"><sup><a
href="#ref-WZK+22" role="doc-biblioref">10</a></sup></span></td>
<td>11</td>
<td>0.68</td>
<td><span class="citation" data-cites="DLT+22"><sup><a
href="#ref-DLT+22" role="doc-biblioref">23</a></sup></span></td>
<td>11</td>
<td>0.68</td>
<td>—</td>
</tr>
<tr>
<td>Development</td>
<td><span class="citation" data-cites="ZZZ+22"><sup><a
href="#ref-ZZZ+22" role="doc-biblioref">11</a></sup></span></td>
<td>6</td>
<td>1.00</td>
<td><span class="citation" data-cites="PCL+22"><sup><a
href="#ref-PCL+22" role="doc-biblioref">24</a></sup></span></td>
<td>6</td>
<td>1.00</td>
<td>—</td>
</tr>
<tr>
<td>Holdout</td>
<td><span class="citation" data-cites="SKC+23"><sup><a
href="#ref-SKC+23" role="doc-biblioref">12</a></sup></span></td>
<td>43</td>
<td>0.68</td>
<td><span class="citation" data-cites="BWY+23"><sup><a
href="#ref-BWY+23" role="doc-biblioref">25</a></sup></span></td>
<td>89</td>
<td>0.67</td>
<td>0.86</td>
</tr>
<tr>
<td>Holdout</td>
<td><span class="citation" data-cites="LBA+25"><sup><a
href="#ref-LBA+25" role="doc-biblioref">13</a></sup></span></td>
<td>92</td>
<td>0.56</td>
<td><span class="citation" data-cites="BRR+24"><sup><a
href="#ref-BRR+24" role="doc-biblioref">26</a></sup></span></td>
<td>102</td>
<td>0.62</td>
<td>—</td>
</tr>
<tr>
<td>Holdout</td>
<td><span class="citation" data-cites="SYL+25"><sup><a
href="#ref-SYL+25" role="doc-biblioref">14</a></sup></span></td>
<td>20</td>
<td>0.31</td>
<td><span class="citation" data-cites="CAB+24"><sup><a
href="#ref-CAB+24" role="doc-biblioref">27</a></sup></span></td>
<td>120</td>
<td>0.66</td>
<td>0.86</td>
</tr>
<tr>
<td>Holdout</td>
<td><span class="citation" data-cites="MTK+26"><sup><a
href="#ref-MTK+26" role="doc-biblioref">15</a></sup></span></td>
<td>64</td>
<td>0.51</td>
<td><span class="citation" data-cites="SGH+24"><sup><a
href="#ref-SGH+24" role="doc-biblioref">28</a></sup></span></td>
<td>20</td>
<td>0.45</td>
<td>—</td>
</tr>
<tr>
<td>Holdout</td>
<td><span class="citation" data-cites="SVK+26"><sup><a
href="#ref-SVK+26" role="doc-biblioref">16</a></sup></span></td>
<td>52</td>
<td>0.71</td>
<td><span class="citation" data-cites="ARF+25"><sup><a
href="#ref-ARF+25" role="doc-biblioref">29</a></sup></span></td>
<td>40</td>
<td>0.69</td>
<td>—</td>
</tr>
<tr>
<td>Holdout</td>
<td><span class="citation" data-cites="YTK+26"><sup><a
href="#ref-YTK+26" role="doc-biblioref">17</a></sup></span></td>
<td>30</td>
<td>0.72</td>
<td><span class="citation" data-cites="GYX+25"><sup><a
href="#ref-GYX+25" role="doc-biblioref">30</a></sup></span></td>
<td>131</td>
<td>0.74</td>
<td>0.88</td>
</tr>
</tbody>
</table>

We did not find direct AUC comparisons in the literature for the breast cancer datasets we used.
Here we compare with some different studies for breast cancer:

- Wang et al.<sup>[31](#ref-WYH+22)</sup> trained random forest classifiers on fecal microbiome data from breast cancer patients and healthy controls,
  achieving an AUC of around 0.68 for stool samples; cross-cohort validation yielded average AUCs of 0.65–0.66.
  These cross-cohort values are in the range of our per-study holdout AUC for breast cancer (Table 8),
  though the studies and cohorts differ.

- Daga and Oudah<sup>[32](#ref-DO24)</sup> reported a peak AUC of 0.83 for breast cancer classification
  using a feature-selected subset with a Bernoulli Naïve Bayes classifier.
  This figure reflects within-cohort performance and is not directly comparable to our holdout results,
  but it illustrates the gap that typically exists between in-study and cross-study evaluation.

Results are consistently lower on the holdout splits than on the in-study test splits,
confirming that test performance computed within the same studies used for training gives overoptimistic estimates of real-world model skill.
This pattern holds across run-level tetramer frequencies and UC/CAP pipelines for tetramer and embeddings.

Comparing holdout performance across Tables 3 and 6, UC/CAP offers a consistent advantage over run-level tetramer features for cancer type classification.
However, it barely improves holdout AUC for cancer diagnosis, despite a large increase on in-study test splits.
Our finding suggests that the compositional diversity captured by cluster abundance profiles
partially breaks the study-level shortcuts that hinder tetramer-based cancer type classifiers.
At the same time, transferable information to discriminate cancer vs healthy may not reside in fine-scale compositional structure.

At 16k tokens per set and 5 sets per run, HyenaDNA sees only around 400 sequences from each sample (assuming 200 nt 16S fragments),
a small fraction of what the tetramer and UC/CAP methods use.
The low number of sequences and their aggregated representation before the classification layer may explain the low accuracy of our current pure deep-learning setup.
In contrast, the hybrid setup combines HyenaDNA embeddings with UC/CAP and achieves better results.

Several directions may improve performance beyond current baselines.
On the feature side, UC/CAP parameters (*K*, *n*<sub>CAP</sub>) could be tuned jointly with the classifier rather than independently,
and soft cluster assignments (Gaussian mixture or fuzzy *k*-means) might better represent the continuous composition of microbial communities.
For HyenaDNA, additional pretraining on 16S rRNA sequences specifically (rather than the human genome)
would better align the model’s learned representations with the target domain.
We could also consider using other embedding models, e.g. SetBERT which has been pretrained on microbial 16S rRNA sequences<sup>[33](#ref-LGA+25)</sup>.

More broadly, our results underscore a general lesson for machine learning applied to genomic and microbiome data:
metrics computed on within-study test splits can be misleading by a wide margin.
Robust evaluation against temporally and geographically diverse holdout cohorts should be a standard requirement in this field<sup>[3](#ref-WSNP22)</sup>.

## Acknowledgments

This study uses data made available by many previous studies.
All contributors to those studies are acknowledged for making this study possible.

## Declaration of generative AI use

Cursor was used for code generation and for writing sections of the manuscript.
Claude Sonnet 4.6 was used for polishing the text; prompts are available in the repository.
Post-AI review and cleanup was done by the author.

## Code and data availability

<https://github.com/jedick/BreCol>

## References

<div id="refs" class="references csl-bib-body" entry-spacing="0" line-spacing="2" markdown="1">

<div id="ref-WPK+19" class="csl-entry" markdown="1">

<span class="csl-left-margin">1. </span><span class="csl-right-inline">Wirbel, J. *et al.* [Meta-analysis of fecal metagenomes reveals global microbial signatures that are specific for colorectal cancer](https://doi.org/10.1038/s41591-019-0406-6). *Nature Medicine* **25**, 679–689 (2019).</span>

</div>

<div id="ref-SHL+25" class="csl-entry" markdown="1">

<span class="csl-left-margin">2. </span><span class="csl-right-inline">Sun, Y. *et al.* [Benchmarking and optimizing microbiome-based bioinformatics workflow for non-invasive detection of intestinal tumors](https://doi.org/10.20517/mrr.2025.75). *Microbiome Research Reports* **4**, 43 (2025).</span>

</div>

<div id="ref-WSNP22" class="csl-entry" markdown="1">

<span class="csl-left-margin">3. </span><span class="csl-right-inline">Whalen, S., Schreiber, J., Noble, W. S. & Pollard, K. S. [Navigating the pitfalls of applying machine learning in genomics](https://doi.org/10.1038/s41576-021-00434-9). *Nature Reviews Genetics* **23**, 169–181 (2022).</span>

</div>

<div id="ref-NPF+23" class="csl-entry" markdown="1">

<span class="csl-left-margin">4. </span><span class="csl-right-inline">Nguyen, E. *et al.* [HyenaDNA: Long-range genomic sequence modeling at single nucleotide resolution](https://proceedings.neurips.cc/paper_files/paper/2023/file/86ab6927ee4ae9bde4247793c46797c7-Paper-Conference.pdf). in *Advances in neural information processing systems* (eds Oh, A. et al.) vol. 36 43177–43201 (Curran Associates, Inc., 2023).</span>

</div>

<div id="ref-AAM+13" class="csl-entry" markdown="1">

<span class="csl-left-margin">5. </span><span class="csl-right-inline">Attraplsi, S., Abbasi, R., Mohammed Abdul, M. K., Salih, M. & Mutlu, E. [Fecal microbiota composition in women in relation to factors that may impact breast cancer development: 625](https://doi.org/10.14309/00000434-201310001-00625). *American Journal of Gastroenterology* **108**, S183 (2013).</span>

</div>

<div id="ref-GJH+15" class="csl-entry" markdown="1">

<span class="csl-left-margin">6. </span><span class="csl-right-inline">Goedert, J. J. *et al.* [Investigation of the association between the fecal microbiota and breast cancer in postmenopausal women: A population-based case-control pilot study](https://doi.org/10.1093/jnci/djv147). *Journal of the National Cancer Institute* **107**, djv147 (2015).</span>

</div>

<div id="ref-GHB+18" class="csl-entry" markdown="1">

<span class="csl-left-margin">7. </span><span class="csl-right-inline">Goedert, J. J. *et al.* [Postmenopausal breast cancer and oestrogen associations with the IgA-coated and IgA-noncoated faecal microbiota](https://doi.org/10.1038/bjc.2017.435). *British Journal of Cancer* **118**, 471–479 (2018).</span>

</div>

<div id="ref-BVW+21" class="csl-entry" markdown="1">

<span class="csl-left-margin">8. </span><span class="csl-right-inline">Byrd, D. A. *et al.* [Associations of fecal microbial profiles with breast cancer and nonmalignant breast disease in the Ghana Breast Health Study](https://doi.org/10.1002/ijc.33473). *International Journal of Cancer* **148**, 2712–2723 (2021).</span>

</div>

<div id="ref-BSR+22" class="csl-entry" markdown="1">

<span class="csl-left-margin">9. </span><span class="csl-right-inline">Bilenduke, E. *et al.* [Impacts of breast cancer and chemotherapy on gut microbiome, cognitive functioning, and mood relative to healthy controls](https://doi.org/10.1038/s41598-022-23793-7). *Scientific Reports* **12**, 19547 (2022).</span>

</div>

<div id="ref-WZK+22" class="csl-entry" markdown="1">

<span class="csl-left-margin">10. </span><span class="csl-right-inline">Wenhui, Y. *et al.* [Variations in the gut microbiota in breast cancer occurrence and bone metastasis](https://doi.org/10.3389/fmicb.2022.894283). *Frontiers in Microbiology* **13**, 894283 (2022).</span>

</div>

<div id="ref-ZZZ+22" class="csl-entry" markdown="1">

<span class="csl-left-margin">11. </span><span class="csl-right-inline">Zhu, Q. *et al.* [L‐norvaline affects the proliferation of breast cancer cells based on the microbiome and metabolome analysis](https://doi.org/10.1111/jam.15620). *Journal of Applied Microbiology* **133**, 1014–1026 (2022).</span>

</div>

<div id="ref-SKC+23" class="csl-entry" markdown="1">

<span class="csl-left-margin">12. </span><span class="csl-right-inline">Shrode, R. L. *et al.* [Breast cancer patients from the Midwest region of the United States have reduced levels of short-chain fatty acid-producing gut bacteria](https://doi.org/10.1038/s41598-023-27436-3). *Scientific Reports* **13**, 526 (2023).</span>

</div>

<div id="ref-LBA+25" class="csl-entry" markdown="1">

<span class="csl-left-margin">13. </span><span class="csl-right-inline">Laborda-Illanes, A. *et al.* [Exploring the interplay between gut microbiota and the melatonergic pathway in hormone receptor-positive breast cancer](https://doi.org/10.3390/ijms26146801). *International Journal of Molecular Sciences* **26**, 6801 (2025).</span>

</div>

<div id="ref-SYL+25" class="csl-entry" markdown="1">

<span class="csl-left-margin">14. </span><span class="csl-right-inline">Sheikh, T. M. M. *et al.* [Integrated insights into gut microbiota and metabolomic landscape in breast cancer patients undergoing adjuvant endocrine therapy](https://doi.org/10.1128/msystems.00879-25). *mSystems* **10**, e00879–25 (2025).</span>

</div>

<div id="ref-MTK+26" class="csl-entry" markdown="1">

<span class="csl-left-margin">15. </span><span class="csl-right-inline">Mahno, N. E., Tay, D. D., Khalid, N. S., Termizi, S. A. & Ahmad, H. F. [Multi-kingdom gut microbiome features associated with breast cancer and menopausal status](https://doi.org/10.1016/j.gutmic.2026.100009). *Gut Microbiology* **2**, 100009 (2026).</span>

</div>

<div id="ref-SVK+26" class="csl-entry" markdown="1">

<span class="csl-left-margin">16. </span><span class="csl-right-inline">Seenivasan, S. N. *et al.* Unique gut microbiome signature with expression of microbial oncogenes among Indian breast cancer patients. *Research Square* <https://doi.org/10.21203/rs.3.rs-8921895/v1> (2026) doi:[10.21203/rs.3.rs-8921895/v1](https://doi.org/10.21203/rs.3.rs-8921895/v1).</span>

</div>

<div id="ref-YTK+26" class="csl-entry" markdown="1">

<span class="csl-left-margin">17. </span><span class="csl-right-inline">Yerlikaya, F. H. *et al.* [Changes in microbiota and short-chain fatty acids, lipopolysaccharide-binding protein and zonulin in people with breast cancer](https://doi.org/10.1007/s44411-026-00523-3). *Bratislava Medical Journal* **127**, 1604–1620 (2026).</span>

</div>

<div id="ref-ZTV+14" class="csl-entry" markdown="1">

<span class="csl-left-margin">18. </span><span class="csl-right-inline">Zeller, G. *et al.* [Potential of fecal microbiota for early-stage detection of colorectal cancer](https://doi.org/10.15252/msb.20145645). *Molecular Systems Biology* **10**, 766 (2014).</span>

</div>

<div id="ref-BRRS16" class="csl-entry" markdown="1">

<span class="csl-left-margin">19. </span><span class="csl-right-inline">Baxter, N. T., Ruffin, M. T., Rogers, M. A. M. & Schloss, P. D. [Microbiota-based model improves the sensitivity of fecal immunochemical test for detecting colonic lesions](https://doi.org/10.1186/s13073-016-0290-3). *Genome Medicine* **8**, 37 (2016).</span>

</div>

<div id="ref-OKN+21" class="csl-entry" markdown="1">

<span class="csl-left-margin">20. </span><span class="csl-right-inline">Okumura, S. *et al.* [Gut bacteria identified in colorectal cancer patients promote tumourigenesis via butyrate secretion](https://doi.org/10.1038/s41467-021-25965-x). *Nature Communications* **12**, 5674 (2021).</span>

</div>

<div id="ref-YDS+21" class="csl-entry" markdown="1">

<span class="csl-left-margin">21. </span><span class="csl-right-inline">Yang, Y. *et al.* [Dysbiosis of human gut microbiome in young-onset colorectal cancer](https://doi.org/10.1038/s41467-021-27112-y). *Nature Communications* **12**, 6757 (2021).</span>

</div>

<div id="ref-YWS+21" class="csl-entry" markdown="1">

<span class="csl-left-margin">22. </span><span class="csl-right-inline">Young, C. *et al.* [The colorectal cancer-associated faecal microbiome of developing countries resembles that of developed countries](https://doi.org/10.1186/s13073-021-00844-8). *Genome Medicine* **13**, 27 (2021).</span>

</div>

<div id="ref-DLT+22" class="csl-entry" markdown="1">

<span class="csl-left-margin">23. </span><span class="csl-right-inline">Du, X. *et al.* [Alterations of the gut microbiome and fecal metabolome in colorectal cancer: Implication of intestinal metabolism for tumorigenesis](https://doi.org/10.3389/fphys.2022.854545). *Frontiers in Physiology* **13**, 854545 (2022).</span>

</div>

<div id="ref-PCL+22" class="csl-entry" markdown="1">

<span class="csl-left-margin">24. </span><span class="csl-right-inline">Png, C.-W., Chua, Y.-K., Law, J.-H., Zhang, Y. & Tan, K.-K. [Alterations in co-abundant bacteriome in colorectal cancer and its persistence after surgery: A pilot study](https://doi.org/10.1038/s41598-022-14203-z). *Scientific Reports* **12**, 9829 (2022).</span>

</div>

<div id="ref-BWY+23" class="csl-entry" markdown="1">

<span class="csl-left-margin">25. </span><span class="csl-right-inline">Bose, M. *et al.* [Analysis of an Indian colorectal cancer faecal microbiome collection demonstrates universal colorectal cancer-associated patterns, but closest correlation with other Indian cohorts](https://doi.org/10.1186/s12866-023-02805-0). *BMC Microbiology* **23**, 52 (2023).</span>

</div>

<div id="ref-BRR+24" class="csl-entry" markdown="1">

<span class="csl-left-margin">26. </span><span class="csl-right-inline">Bars-Cortina, D. *et al.* [Comparison between <span class="nocase">16S rRNA</span> and shotgun sequencing in colorectal cancer, advanced colorectal lesions, and healthy human gut microbiota](https://doi.org/10.1186/s12864-024-10621-7). *BMC Genomics* **25**, 730 (2024).</span>

</div>

<div id="ref-CAB+24" class="csl-entry" markdown="1">

<span class="csl-left-margin">27. </span><span class="csl-right-inline">Conde-Pérez, K. *et al.* [The multispecies microbial cluster of Fusobacterium, Parvimonas, Bacteroides and Faecalibacterium as a precision biomarker for colorectal cancer diagnosis](https://doi.org/10.1002/1878-0261.13604). *Molecular Oncology* **18**, 1093–1122 (2024).</span>

</div>

<div id="ref-SGH+24" class="csl-entry" markdown="1">

<span class="csl-left-margin">28. </span><span class="csl-right-inline">Shastry, R. P. *et al.* [Emergence of rare and low abundant anaerobic gut Firmicutes is associated with a significant downfall of Klebsiella in human colon cancer](https://doi.org/10.1016/j.micpath.2024.106726). *Microbial Pathogenesis* **193**, 106726 (2024).</span>

</div>

<div id="ref-ARF+25" class="csl-entry" markdown="1">

<span class="csl-left-margin">29. </span><span class="csl-right-inline">Ashraf, H. *et al.* [On exploring cross-sectional stability and persistence of microbiome in a multiple body site colorectal cancer dataset](https://doi.org/10.3389/fmicb.2025.1449642). *Frontiers in Microbiology* **16**, 1449642 (2025).</span>

</div>

<div id="ref-GYX+25" class="csl-entry" markdown="1">

<span class="csl-left-margin">30. </span><span class="csl-right-inline">Guodong, W. *et al.* [Fecal occult blood affects intestinal microbial community structure in colorectal cancer](https://doi.org/10.1186/s12866-024-03721-7). *BMC Microbiology* **25**, 34 (2025).</span>

</div>

<div id="ref-WYH+22" class="csl-entry" markdown="1">

<span class="csl-left-margin">31. </span><span class="csl-right-inline">Wang, N. *et al.* [Identifying distinctive tissue and fecal microbial signatures and the tumor-promoting effects of deoxycholic acid on breast cancer](https://doi.org/10.3389/fcimb.2022.1029905). *Frontiers in Cellular and Infection Microbiology* **12**, 1029905 (2022).</span>

</div>

<div id="ref-DO24" class="csl-entry" markdown="1">

<span class="csl-left-margin">32. </span><span class="csl-right-inline">Daga, P. & Oudah, M. Machine learning and gut microbiome for breast cancer screening. in *2024 IEEE conference on computational intelligence in bioinformatics and computational biology (CIBCB)* 1–7 (2024). doi:[10.1109/CIBCB58642.2024.10702110](https://doi.org/10.1109/CIBCB58642.2024.10702110).</span>

</div>

<div id="ref-LGA+25" class="csl-entry" markdown="1">

<span class="csl-left-margin">33. </span><span class="csl-right-inline">Ludwig, I., David W *et al.* [SetBERT: The deep learning platform for contextualized embeddings and explainable predictions from high-throughput sequencing](https://doi.org/10.1093/bioinformatics/btaf370). *Bioinformatics* **41**, btaf370 (2025).</span>

</div>

</div>

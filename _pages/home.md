---
layout: splash
permalink: /
title: Jeffrey Dick

header:
  overlay_color: "#000"
  overlay_filter: "0.5"
  overlay_image: /assets/siteimages/splash_banner.jpg
  actions:
    - label: "Connect"
      url: "/connect/"
excerpt: "*Machine learning engineer coming from science,<br>turning research into seriously useful apps*"

intro: 
  - excerpt: "<h3>This portfolio tells a story of my journey starting as a scientist making software<br>and using data, to becoming an ML engineeer building reliable systems for industry</h3>"
---

{% include feature_row id="intro" type="center" %}

## Highlighted projects

- **[AI4citations](https://github.com/jedick/AI4citations): AI-powered citation verification**

<img src="/assets/siteimages/AI4citations_screenshot.png" alt="AI4citations screenshot" style="width:30%;"/>

  - Checks the veracity of scientific claims against cited text
  - Web app built with Gradio frontend, deployed on Hugging Face
  - Built API **integration tests with continuous integration (CI)** through GitHub Actions to ensure working product with each commit
  - App collects user feedback into Hugging Face datasets
  - *The culmination of my [ML engineering capstone project](https://github.com/jedick/MLE-capstone-project), demonstrating skills in deploying and monitoring models and feedback collection for constant improvements*

- **[pyvers](https://github.com/jedick/pyvers): NLP data processing and model training**

<img src="/assets/siteimages/pyvers_banner.png" alt="pyvers banner" style="width:30%;"/>

  - Implemented data processing from diverse data sources with normalized labels
  - Devised shuffled training method to train on multiple data sources, leading to **7% improvement in F1 score over SOTA models** ([see blog post for details](blog/experimenting-with-transformer-models-for-citation-verification/))
  - Implemented in PyTorch lightning for reproducible & scalable training
  - *This project was the foundation for improved training using multiple datasets and leveraged software frameworks for model deployment locally or on cloud services, building my skills in data and software engineering*

- **[CHNOSZ](https://chnosz.net): Enabling reproducible scientific workflows since 2009**

<img src="/assets/siteimages/CHNOSZ_banner.png" alt="CHNOSZ banner" style="width:30%;"/>

  - Developed open-source R package enabling reproducible workflows to model chemical systems with intuitive visualizations
  - [Maintained on CRAN](https://cran.r-project.org/package=CHNOSZ) since 2009
  - Cited more than [200](https://scholar.google.com/scholar?cites=18385152422710735148&as_sdt=2005&sciodt=0,5&hl=en) [times](https://scholar.google.com/scholar?cites=8675465244739999021&as_sdt=2005&sciodt=0,5&hl=en) by researchers around the world
  - Automated data consistency checks provide confidence in the community-driven thermodynamic database, which continues to grow every year
  - Massive documentation effort, including help pages, examples, demos, and vignettes
  - API supports third-party contributions, including a Shiny frontend and a Python interface

## CRAN packages and other software projects

- CRAN packages I maintain:
  - [CHNOSZ](https://doi.org/10.32614/CRAN.package.CHNOSZ): Thermodynamic calculations and diagrams for geochemistry
  - [canprot](https://doi.org/10.32614/CRAN.package.canprot): Chemical analysis of proteins
  - [chem16S](https://doi.org/10.32614/CRAN.package.chem16S): Chemical features of microbial communities

- [orpML](https://github.com/jedick/orpML): Predicting environmental variables from microbial abundances
  - Supporting code for a research project in environmental microbiology (ORP stands for oxidation-reduction potential)
  - Classical machine learning with scikit-learn and deep learning with PyTorch
  - Improved performance of ML models by deriving features from thermodnamic models

- [R-svg-intepreter](https://github.com/jedick/R-svg-interpreter): R script to visualize an SVG file with base R graphics
  - **Written with AI assistance using Cursor**
  - [Posted on the R-help mailing list](https://stat.ethz.ch/pipermail/r-help/2025-July/481079.html) to answer a user's request

## PRs, issues, etc.

- Created [CHNOSZ Discussions forum on GitHub](https://github.com/jedick/CHNOSZ/discussions) for user support
- [LangSmith onboarding: Issues with experiment logging](https://github.com/nhuang-lc/langsmith-onboarding/issues/2)
  - Explains how to update evaluation notebooks for compatibility with current API
- [Gradio app: Fix ValueError in Controlling the Reload demo](https://github.com/gradio-app/gradio/pull/11220)
  - PR accepted by Gradio maintainer to make documentation example work with HF pipelines

## Academic research

- [Reviewer for software and ML papers in science journals](https://webofscience.clarivate.cn/wos/author/record/K-1619-2013)
- [Author of 20+ first-author papers and 50+ coauthored papers](http://scholar.google.com/scholar?hl=en)
- Long-term committment to reproducible research
  - [JMDplots](https://github.com/jedick/JMDplots) R package reproduces plots for 20 of my papers going back to 2006
- For more info, see my [Research Overview](https://chnosz.net/jeff)

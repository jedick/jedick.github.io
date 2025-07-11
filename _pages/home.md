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

### [AI4citations](https://github.com/jedick/AI4citations): AI-powered citation verification

<img src="/assets/siteimages/AI4citations_screenshot.png" alt="AI4citations screenshot" style="width:30%;"/>

- Checks the veracity of scientific claims against cited text
- Web app built with Gradio frontend, deployed on Hugging Face
- **Built API integration tests with continuous integration** (CI) in GitHub Actions to ensure working product with each commit
- App collects user feedback into Hugging Face datasets
- *The culmination of my [ML engineering capstone project](https://github.com/jedick/MLE-capstone-project), demonstrating skills in deploying and monitoring models and feedback collection for constant improvements*

### [pyvers](https://github.com/jedick/pyvers): NLP data processing and model training

<img src="/assets/siteimages/pyvers_banner.png" alt="pyvers banner" style="width:30%;"/>

- Implemented data processing from multiple data sources with normalized labels
- Devised shuffled training method to achieve **7% improvement in F1 score over SOTA models** ([see blog post for details](blog/experimenting-with-transformer-models-for-citation-verification/))
- Implemented in PyTorch lightning for reproducible & scalable training
- *This project was the foundation for improved training using multiple datasets and leveraged software frameworks for model deployment locally or on cloud services, building my skills in data and software engineering*

### [CHNOSZ](https://chnosz.net): Enabling reproducible scientific workflows

<img src="/assets/siteimages/CHNOSZ_banner.png" alt="CHNOSZ banner" style="width:30%;"/>

- Developed open-source R package with reproducible workflows to model chemical systems and make intuitive visualizations
- [Maintained on CRAN](https://cran.r-project.org/package=CHNOSZ) since 2009 and cited more than [200](https://scholar.google.com/scholar?cites=18385152422710735148&as_sdt=2005&sciodt=0,5&hl=en) [times](https://scholar.google.com/scholar?cites=8675465244739999021&as_sdt=2005&sciodt=0,5&hl=en) by researchers around the world
- **Automated data consistency checks increase confidence** in the community-driven thermodynamic database
- Massive documentation effort, including help pages, examples, demos, and vignettes
- API supports third-party contributions, including a Shiny frontend and a Python interface

## Software projects and packages

- CRAN packages I maintain:
  - [CHNOSZ](https://doi.org/10.32614/CRAN.package.CHNOSZ): Thermodynamic calculations and diagrams for geochemistry
  - [canprot](https://doi.org/10.32614/CRAN.package.canprot): Chemical analysis of proteins
  - [chem16S](https://doi.org/10.32614/CRAN.package.chem16S): Chemical features of microbial communities

- [orpML](https://github.com/jedick/orpML): Predicting oxidation-reduction potential from microbial abundances
  - Supporting code for a research project in environmental microbiology
  - Classical machine learning with scikit-learn and deep learning with PyTorch
  - Improved performance of ML models by deriving features from thermodynamic models

- [R-svg-intepreter](https://github.com/jedick/R-svg-interpreter): R script to visualize an SVG file with base R graphics
  - **Written with AI assistance using Cursor**
  - [Posted on the R-help mailing list](https://stat.ethz.ch/pipermail/r-help/2025-July/481079.html) to answer a user's request

## PRs, issues, and discussions

- [Created CHNOSZ Discussions forum on GitHub](https://github.com/jedick/CHNOSZ/discussions) for user support and engagement
- [Answered LangChain question: Getting top k documents for ParentDocumentRetriever](https://github.com/langchain-ai/langchain/discussions/17582)
  - Made sense of the documentation to show how to pass keyword arguments to the search function
- [Answered LangChain issue: Using local Hugging Face pipeline](https://github.com/langchain-ai/langchain/issues/31324)
  - Digested the error messsage and docs to correctly specify a missing component needed to build private chatbots
- [Answered LangGraph question: Extract tool name during streaming](https://github.com/langchain-ai/langgraph/discussions/3042)
  - Found solution for displaying tool names used in a chatbot application (first answer, 6 months after OP)
- [Posted LangSmith issue: Fixes for experiment logging](https://github.com/nhuang-lc/langsmith-onboarding/issues/2)
  - Updated evaluation notebooks for compatibility with current API (allows reproducing steps in LangSmith onboarding videos)
- [Committed to Gradio: Fix ValueError in Controlling the Reload demo](https://github.com/gradio-app/gradio/pull/11220)
  - Fixed bug in documentation example to correctly handle pipeline output (PR accepted by Gradio maintainers)

## Academic research

- [Reviewer for software and ML papers in science journals](https://webofscience.clarivate.cn/wos/author/record/K-1619-2013)
- [Published 20+ first-author papers and 50+ coauthored papers](http://scholar.google.com/scholar?hl=en)
- Long-term committment to reproducible research
  - [JMDplots](https://github.com/jedick/JMDplots) package reproduces plots for 20 of my papers going back to 2006
  - See my [research overview](https://chnosz.net/jeff) for more info
- *Transferable skills: scientific computing, project management, writing, critical thinking*

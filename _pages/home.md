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
excerpt: "*Machine learning* and research software *engineer*,<br>turning data and cutting-edge research into practical tools."

intro: 
  - excerpt: "<h3>Welcome to my technical portfolio.<br>Here you can learn about some of the cool things I've built!</h3>"

feature_row:
  - image_path: /assets/siteimages/CHNOSZ_banner.png
    title: "Software Engineering"
    excerpt: "
        My software engineering journey started with the **CHNOSZ** R package for thermodynamic calculations and diagrams.
        I have maintained this package [on CRAN](https://cran.r-project.org/package=CHNOSZ) since 2009 and it is used by [100+](https://scholar.google.com/scholar?cites=18385152422710735148&as_sdt=2005&sciodt=0,5&hl=en) [research groups](https://scholar.google.com/scholar?cites=8675465244739999021&as_sdt=2005&sciodt=0,5&hl=en) around the world.
        One of the reasons for its success is *data quality* ([blog post](blog/thermodynamic-data-consistency-Li-mica/)) as much as the computational and visualization features.
   "
    url: "https://chnosz.net"
    btn_label: "CHNOSZ website"
    btn_class: "btn--primary"
  - image_path: /assets/siteimages/NLP_banner.png
    title: "NLP Engineering"
    excerpt: "
        My background in scientific software combines with a passion for writing to build robust *claim-verification systems* in the field of Natural Langauge Processing.
        I've mastered the art of fine-tuning transformer models ([blog post](blog/experimenting-with-transformer-models/)).
        My approach speaks to the MLOps paradigm of *iterating on the data* to create a powerful evidence-retrieval pipeline.
        This result is a state-of-the art system that helps writers and editors verify quotation accuracy in scientific publications.
    "
    url: "https://github.com/jedick/AI4citations"
    btn_label: "AI4citations repository"
    btn_class: "btn--primary"
  - image_path: /assets/siteimages/pyvers_banner.png
    title: "ML Engineering"
    excerpt: "
        I wrote the **pyvers** Python package for reproducible data processing and iterative ML experiments with the [pytorch-lightning](https://github.com/Lightning-AI/pytorch-lightning) framework for deep learning.
        Putting it all together with [litserve](https://github.com/Lightning-AI/litserve/) to deploy the model at scale and a [Gradio](https://github.com/gradio-app/gradio) frontend makes it easy for anybody to use the claim verification system.
        (*Credit for citation example: [Sarol et al., 2024](https://doi.org/10.1093/bioinformatics/btae420).*)
    "
    url: "https://github.com/jedick/pyvers"
    btn_label: "pyvers repository"
    btn_class: "btn--primary"
---

{% include feature_row id="intro" type="center" %}

{% include feature_row %}

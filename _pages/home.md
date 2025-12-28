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
    - label: "GitHub"
      url: "https://github.com/jedick"
excerpt: "*Building reliable AI systems for data science*"

featured_projects:
  - image_path: /assets/siteimages/R-help-chat_banner.png
    alt: "R-help chatbot banner"
    title: "Making knowledge accessible through conversational AI"
    excerpt: >
      Agentic retrieval for 10+ years of email archives, designed for deep research and continual data updates.
      <i class="fa-brands fa-youtube"></i> [Walkthrough video](https://youtu.be/mLQqW7zea-k)
    url: "/r-help-chat/"
  - image_path: /assets/siteimages/noteworthy-differences_banner.png
    alt: "Noteworthy Differences banner"
    title: "AI alignment for detecting meaningful changes"
    excerpt: "This project leverages AI alignment with human-in-the-loop to build a practical solution for filtering signal from noise in document updates."
    url: "/noteworthy-differences/"
  - image_path: /assets/siteimages/AI4citations_banner.png
    alt: "AI4citations banner"
    title: "Finding inaccurate citations with AI"
    excerpt: "Taking citation verification analysis from research to production through model optimization, deployment, and feedback collection."
    url: "/ai4citations/"
  - image_path: /assets/siteimages/CHNOSZ_diagram.png
    alt: "CHNOSZ workflows"
    title: "Building scientific software that lasts"
    excerpt: "Enabling scientific discovery through chemical data analysis and visualization workflows and a commitment to testing and long-term maintenance."
    url: "/chnosz/"
featured_posts:
  - image_path: /assets/images/2025-12-26-combating-concept-drift-in-LLM-applications/concept-drift.jpg
    alt: "Combating concept drift through feedback-driven prompt engineering"
    title: "Combating concept drift in LLM applications"
    excerpt: >
      Your LLM application works beautifully at launch. 
      The model understands user preferences, accuracy metrics look great, and feedback is positive.
      Then, gradually—or sometimes suddenly—performance starts to degrade.
      Users complain.
      Metrics slide.
      What happened?
    url: "/blog/combating-concept-drift-in-LLM-applications/"
  - image_path: /assets/images/2025-05-08-modern-understanding-of-overfitting-and-generalization-in-machine-learning/double-descent.svg
    alt: "Double Descent: Rethinking Overfitting"
    title: "Modern understanding of overfitting and generalization in machine learning"
    excerpt: >
      The conventional wisdom about the bias-variance tradeoff in machine learning has been dramatically challenged by modern neural networks.
      Traditionally, we believed that increasing model complexity would decrease bias but increase variance.
      However, recent research reveals that highly overparameterized models often generalize exceptionally well despite perfectly fitting the training data.
    url: "/blog/modern-understanding-of-overfitting-and-generalization-in-machine-learning/"
  - image_path: /assets/images/2025-03-20-experimenting-with-transformer-models-for-citation-verification/accuracy_curves.png
    alt: "Accuracy curves for training DeBERTa transformer model with citation verification datasets"
    title: "Experimenting with transformer models for citation verification "
    excerpt: >
      This article provides a systematic comparison of transformer-based architectures for scientific claim verification,
      evaluating their performance across multiple datasets and examining the trade-offs between
      model complexity, computational efficiency, and generalization capabilities.
    url: "/blog/experimenting-with-transformer-models-for-citation-verification/"
---

<h2>Where Science Meets AI Innovation</h2>

I've spent over a decade turning complex research questions into elegant software solutions.
I'm always on the lookout for opportunities to pursue my passion for building AI systems that are **dependable, adaptable, and impactful**.

My unique perspective combines rigorous scientific methodology with modern ML engineering practices—creating solutions that researchers and industry professionals can trust with their most important data.

---

## 💼 Featured Projects

{% include feature_row id="featured_projects" %}

## 📝 Featured Posts

{% include feature_row id="featured_posts" %}

<style>

.feature__wrapper {
  /* Cursor used this but it makes cards too narrow */
  /*
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(450px, 1fr));
  */
  display: flex;
  gap: 1.5rem;
  margin: 2rem 0;
  max-width: 1400px;
  margin-left: auto;
  margin-right: auto;
}

.feature__item {
  border: 1px solid #e8e8e8;
  border-radius: 4px;
  overflow: hidden;
  transition: box-shadow 0.3s ease;
  display: flex;
  flex-direction: column;
}

.feature__item:hover {
  box-shadow: 0 4px 8px rgba(0,0,0,0.1);
}

.archive__item {
  display: flex;
  flex-direction: column;
  height: 100%;
}

.archive__item-teaser {
  flex-shrink: 0;
}

.archive__item-teaser img {
  width: 100%;
  height: auto;
  display: block;
  object-fit: cover;
}

.archive__item-body {
  padding: 1.5rem;
  flex-grow: 1;
  display: flex;
  flex-direction: column;
}

.archive__item-title {
  margin-top: 0;
  margin-bottom: 0.5rem;
}

.archive__item-title a {
  color: #2c3e50;
  text-decoration: none;
}

.archive__item-title a:hover {
  color: #1a252f;
  text-decoration: underline;
}

.archive__item-excerpt {
  color: #666;
  font-size: 0.95rem;
  line-height: 1.6;
  flex-grow: 1;
}
</style>

<!--

---

## 🚧 Projects In Development: Pushing AI Boundaries 🚧

### [Statistical AI Agents](https://github.com/jedick/plotmydata): Autonomous data analysis
*Building AI agents that can independently perform statistical analysis and generate insights*

### [Docker Microservices for Science](https://github.com/jedick/speciation-microservice): Scalable computing architecture
*Containerized scientific computing services for cloud-native research workflows*

-->


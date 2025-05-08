---
title: "Modern understanding of overfitting and generalization in machine learning"
date: 2025-05-08T09:05:48+08:00
categories:
  - Blog
tags:
  - Machine Learning
  - Overfitting
  - Bias-Variance Tradeoff
classes: wide
---

![Double Descent: Rethinking Overfitting](/assets/images/2025-05-08-modern-understanding-of-overfitting-and-generalization-in-machine-learning/double_descent_graphic.svg)

In a [previous post]({% post_url 2025-03-20-experimenting-with-transformer-models-for-citation-verification %}),
I described my experience with fine-tuning transformer models on small NLP datasets with less than a few thousand examples.
One of the goals of that exercise (a step in my [ML capstone project](https://github.com/jedick/ML-capstone-project)) was to reduce overfitting.
I found that transformer models began overfitting right away, with a massive decrease in training loss in the first few epochs, while validation loss increased.
However, the validation accuracy showed improvements while fine-tuning for up to ten epochs.
In other words, the model generalizes well despite classic signals of overfitting, but I didn't have a theoretical justification for using this model.

I brainstormed some causes (e.g. domain adaptation effects and contrasting statistical meaning of loss and accuracy) but didn't find an a convincing explanation.
Then, I came across an [IBM Think post about LoRA](https://www.ibm.com/think/topics/lora) (Low-Rank Adaptation) by Joshua Nobel.
He writes that "information loss ... [which is] comparable to model overfitting ... is often minimal because deep learning models are so highly overparameterized".
This got me thinking about differences between overfitting and overparameterization.
A few web searches on "overparameterized vs overfitting" uncovered a subfield of research that challenges the classical notion of the bias-variance tradeoff.
These findings (summarized below) support my earlier decision to overfit the model to achieve better generalization.

## Two-Minute Summary

The conventional wisdom about the bias-variance tradeoff in machine learning has been dramatically challenged by modern neural networks.
Traditionally, we believed that increasing model complexity would decrease bias but increase variance,
creating a U-shaped risk curve where optimal performance occurs at moderate complexity (Belkin et al., 2019; Rocks and Mehta, 2022).
However, recent research reveals that highly overparameterized models often generalize exceptionally well despite perfectly fitting the training data –
a phenomenon previously considered impossible.

- [Zhang et al. (2017)](https://openreview.net/forum?id=Sy8gdB9xx) demonstrated that deep neural networks can easily memorize random noise,
  yet still generalize well on real data, suggesting that traditional complexity measures fail to explain their success.
- [Belkin et al. (2019)](https://doi.org/10.1073/pnas.1903070116) introduced the "double descent" phenomenon where test error follows a U-curve until
  the interpolation threshold (where training error reaches zero), but then begins to decrease again as model size continues to increase.
- [Yang et al. (2020)](https://proceedings.mlr.press/v119/yang20j.html) further explained this by showing that while bias monotonically decreases with model
  complexity as expected, variance actually follows a bell curve – increasing until the interpolation threshold, then decreasing again in overparameterized models.
- [Bartlett et al. (2020)](https://doi.org/10.1073/pnas.1907378117) characterized when linear models can perfectly fit training data yet still achieve near-optimal
  prediction accuracy, revealing that benign overfitting requires significant overparameterization and depends on the effective rank of the data covariance.
- [Rocks and Mehta (2022)](https://doi.org/10.1103/PhysRevResearch.4.013201) provided theoretical foundations for this behavior,
  demonstrating how both bias and variance can decrease beyond the interpolation threshold.

## Practical Advice for ML Engineers

1. **Don't fear overparameterization**:
Contrary to traditional advice, using models with many more parameters than data points can lead to better generalization.
While regularization can still be useful, perfect fits to training data aren't necessarily problematic and can generalize well.

2. **Understand the new bias-variance landscape**:
Variance no longer monotonically increases with model complexity but follows a bell curve, peaking at the interpolation threshold.
The best performance often occurs in the overparameterized regime where training error reaches zero.

3. **Scale your models appropriately**:
Neural networks should be large enough to easily fit the training data with minimal loss.

## How to Respond to Conventional Advice About Reducing Overfitting

When someone suggests reducing model complexity to avoid overfitting:
- Explain that modern research shows overfitting isn't simply determined by model size
- Clarify that perfectly fitting training data can actually generalize well with sufficient overparameterization
- Distinguish between "harmful memorization" and "benign overfitting"
- Consider scaling up model size rather than down if experiencing poor generalization
- Suggest experimenting with models on both sides of the interpolation threshold

## Conclusion

These findings represent a paradigm shift in our understanding of generalization in machine learning, suggesting that bigger models with zero training error can actually be the optimal choice in many scenarios.

## Document Lineage

I downloaded the five papers linked above, extracted the abstracts and parts of the introductions, and asked Claude (3.7 Sonnet) to summarize the extracts.
This post is an edited version of [the chat](https://claude.ai/share/bdaf960a-7f20-48f9-8c55-cb9329f5423e) with the following modifications:

- Claude cited Bartlett et al. (2020) for the U-shaped risk curve.
  I changed this to Belkin et al. (2019) and Rocks and Mehta (2022) as they are more relevant citations.
- In a separate chat, I asked Claude to summarize the abstract of Bartlett et al. (2020), then added it to the list in the first section.
- I compressed the "Practical Advice" list from five to three items and removed the citations from this part.
- I asked Claude to create a graphic.
  This produced less than perfect results (see [the chat](https://claude.ai/share/f4ec0882-b328-42b0-ae89-7c9cc205c0ae)), so I hand-edited the SVG file in Inkscape.
  The inspiration for this diagram comes from Belkin et al. (2019).

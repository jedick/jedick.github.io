---
title: "LLMs in claim verification"
date: 2024-12-23T12:23:18+08:00
categories:
  - Blog
tags:
  - LLMs
---

Scientific papers make lots of claims with supporting citations. However,
even well-intentioned writers make mistakes, and automated citation
verification is an important task for improving quality of research papers.
Welcome to my year-end roundup on using LLMs for claim verification.

Whether available evidence supports or refutes a claim is a practical question
for researchers and policymakers alike. While NLP methods using deep learning
have been developed for quite some time, 2024 saw a major increase in the
number of papers using LLMs to tackle this challenge.  The studies here reveal
potential advantages of LLMs including zero-shot claim verification and high
accuracy on challenging tasks.

Some background to the field: claim verification models often start with
large-scale datasets derived from sources like Wikipedia, but datasets based
on research papers facilitate more specific task of scientific claim
verification. [SciFact](https://github.com/allenai/scifact?trk=public_post_comment-text),
published in 2020, is one well-known dataset that
consists of claims and evidence statements, the latter extracted from cited
abstracts or papers. The claim-evidence pairs used for training are manually
annotated with labels indicating whether the evidence SUPPORTS or REFUTES the
claim or provides Not Enough Information (NEI) about the claim. Claim
verification refers to methods to assign these labels. However, the related
tasks of claim identification and evidence retrieval also need to be developed for
a holistic solution to verifying claims.

## [Language Models Hallucinate, but May Excel at Fact Verification](https://arxiv.org/abs/2310.14564?trk=public_post_comment-text)

A collaboration between Tsinghua University and the Allen Institute for AI,
this study evaluates the extent of hallucinations in GPT-3.5 (up to 25% of the
times) and tests the fact-verification abilities of several instruction-tuned
LLMs on aggregated Wiki-domain and Scientific domain-specific datasets.
Surprisingly, FLAN-T5, an LLM with lower fact-generation capability than
GPT-3.5, performs better in the fact-verification task. The study reveals
important consideration needed for repurposing LLMs as fact verifiers.

## [Zero-shot Scientific Claim Verification Using LLMs and Citation Text](https://aclanthology.org/2024.sdp-1.25?trk=public_post_comment-text)

This exciting preprint from the University of Washington in July 2024 tests
the ability of LLMs to verify claims directly from citation texts. It's based
on the SciFact dataset but uses original citances rather than rewritten
claims. The dataset is augmented with LLM-generated negations. The authors
find that prompting GPT-4 with examples from the dataset yields comparable
performance to state-of-the art models finetuned on claim-evidence pairs.

## [Can Large Language Models Detect Misinformation in Scientific News Reporting?](https://arxiv.org/abs/2402.14268?trk=public_post_comment-text)

Posted in February 2024, this study from researchers at Stevens Institute of
Technology and Peraton Labs in New Jersey aims to use LLMs to detect
misinformation in scientific reporting. The authors compile a new labeled
dataset (SciNews) by prompting Lllama2-7B to generate a "True Article" and a
"Convincing False Article" for each of 2000+ selected highly cited articles.
They describe a prompt engineering architecture named SERIf which breaks down
the process of identifying misinformation "in the wild" into specific tasks of
summarization (understanding the gist of the news article), evidence
retrieval, and inference. Overall an interesting look into designing effective
prompt strategies for fact verification.

## [Long-form Factuality in Large Language Models](https://arxiv.org/abs/2403.18802?trk=public_post_comment-text)

Updated in November 2024, this study From Google DeepMind, Stanford
University, and UIUC develops a Search-Augmented Factuality Evaluator (SAFE)
that uses LLMs to separate text into individual claims, then uses evidence
retrieved from Google Search to predict whether the available evidence
support, does not support, or is irrelevant to each claim. _My insight_: this
approach to deciding whether a claim is supported by world knowledge is
directly transferable to the problem of claim verification in science papers
and directly tackles the claim identification problem which is not addressed
by other studies.

It's clear that LLMs are poised to make a huge impact to scientific claim
verification with downstream effects for biomedical studies but also
publishers. I'm working on a project, [AI4citations](https://github.com/jedick/AI4citations?trk=public_post_comment-text),
to automate claim verification of citations, starting with training using transformers but
actively looking for improvements by leveraging LLMs through prompt design,
agental systems. Feel free to comment if you have any additions to this list
or ideas about where the field is headed!

---

*What you just read is the the original piece I wrote.*

See my [LinkedIn post](https://www.linkedin.com/posts/jeffrey-m-dick_scientific-papers-rely-heavily-on-citations-activity-7276840709565947904-epIw) for the AI-edited version with Claude 3.5 Sonnet.
The prompt is below (slightly edited):

Please proofread this piece that I plan to post to my LinkedIn network (and also to be made public).
I am trying to inform about the state of the art as well as my own place in the field.
Add some subtle graphical elements such as bullets or emoji.
Make it exciting and keep a professional tone.
Make the piece more concise - shorten it by about 30%.
The headings are paper titles and should not be changed.


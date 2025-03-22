---
title: "What can go wrong? Side-by-side comparison of pretrained DeBERTa before and after fine-tuning"
date: 2025-03-22T19:55:24+08:00
categories:
  - Blog
tags:
  - MLOps
  - NLP
  - Claim Verification
classes: wide
---

*What can possibly go wrong*? This is the question Andrew Ng says we should ask in order to devise useful metrics for monitoring production deployments of ML systems.
In more detail, performance metrics (accuracy, F1 score, AUROC, etc.) can tell you how your model does on a test set, but what use are they if your model doesn't perform as expected in a real-world scenario?

One way (not the only way) of answering these questions is to stress-test your model with weird inputs.
Or not even weird inputs, but inputs that might be able to catch unexpected outputs.
And what is "unexpected"?
It could just be that the model gives a different answer than a baseline -- suggesting that either the model or the baseline is less than perfect.
In other words, *look at your model's outputs* is just as good advice as *look at your data*.
To do this I created an app based on a LitServe server and Gradio frontend that will be uploaded to the pyvers repo.
Here's an annotated screenshot:

![pyvers app screenshot]({{ site.url }}{{ site.baseurl }}/assets/images/2025-03-23-what-can-go-wrong/pyvers_app_screenshot.png)

In a previous post I documented my experience fine-tuning a pretrained DeBERTa model.
The pretrained model from HuggingFace was pretrained on various NLI (Natural Language Inference) datasets that label pairs of sentences with one of three classes (entailment, neutral, or contradiction).
I fine-tuned this model on two scientific citation verification datasets, SciFact and Citation-Integrity, which have analogous labels of Support, Not Enough Information (NEI), or Refute.

So, what could possibly go wrong? Well, the *pretrained model gets confused when the sentences are missing a period (full stop) at the end of the sentence!*
In contrast, the fine-tuned model performs well on a simple hypothesis ("This tree is green") based on a given premise ("All trees are green"), whether or not they have periods at the end.
Additional results are listed below; cases where the pretrained and fine-tuned models differ in the highest-probability predictions are highlighted.

|Evidence|Claim|Pretrained Model|Fine-tuned Model|Notes / Interpretation|
|---|---|---|---|---|
|All trees are green|This tree is green|**NEI 0.784**|**Support 0.947**|The *pretrained* model is fooled by missing periods.|
|All trees are green.|This tree is green.|Support 0.614|Support 0.994|The *fine-tuned* model has higher confidence than the *pretrained* model for deductive statements|
|The patient died from cancer.|Cancer is a deadly disease.|Support 0.945|Support 0.994|OK|
|The patient died from COVID.|Cancer is a deadly disease.|NEI 0.853|NEI 0.991|OK|
|The patient died from cancer.|COVID is a deadly disease.|**Refute 0.724**|**NEI 0.998**|Unknown vocabulary may cause the *pretrained* model to refute rather than NEI|
|The patient died from cancer.|The patient is still alive.|Refute 0.999|Refute 0.999|OK|
|The patient died from cancer.|The patient died yesterday.|NEI 0.998|NEI 0.999|OK|
|The patient died from cancer.|The patient was alive yesterday.|**NEI 0.834**|**Refute 0.927**|Unknown contexts may cause the *fine-tuned* model to refute rather than NEI|
|The patient will not be treated tomorrow.|The patient's treatment has finished.|**NEI 0.603**|**Support 0.990**|The *pre-trained* model is reluctant to draw conclusions|
|The patient will not be treated tomorrow.|Yesterday was the last day of the patient's treatment.|**Refute 0.406**|**Support 0.629**|*Opposite decisions!*|
|The patient will not be treated tomorrow.|Today is the last day of the patient's treatment.|Support 0.913|Support 0.997|*Both* models can be tricked by almost opposites (today-tomorrow)|
|This is the last day of the patient's treatment.|The patient will go home tomorrow.|NEI 0.972|NEI  0.995|OK|
|This is the last day of the patient's treatment.|The patient will be treated tomorrow.|Refute 0.995|Refute 0.994|OK|
|This is the last day of the patient's treatment.|The patient will not be treated tomorrow.|Support 0.900|Support 0.996|OK|
|The patient's treatment has finished.|The patient will not be treated tomorrow.|NEI 0.994|NEI 0.997|*Both* models have poor performance on "common sense" statements|
|The patient has declined treatment.|The patient will not be treated unless they change their mind.|**NEI 0.978**|**Support 0.841**|The *fine-tuned* model makes decisions about more complex claims|

Overall, fine tuning seems to make the model more decisive.
I found only one example where the pretrained and fine-tuned models give opposite decisions (Refute vs Support).
The last comparison in the table is important for scientific claim verification, as it suggests *better reasoning about complex claims* in the fine-tuned model.

Another thing that can go wrong is the *order of evidence and claim statements* in the tokenizer.
I found that the pretrained DeBERTa model produces reasonable results on zero-shot classification (e.g. predictions on the SciFact dataset without any fine-tuning) only if the evidence statement is the *first* argument in the tokenizer, and the claim statement is *second*.
Where is this behavior documented?
I haven't found the answer yet.
But it is probably useful to know that reversed evidence and claim statements (or premise and hypothesis) statements in the tokenizer can trip up an app designed for zero-shot or open claim verification.

Here we went beyond performance metrics to *look at a model's outputs*, getting a better feel for how fine-tuning changes a model's behavior, and we identified *two things that can go wrong* (missing periods in the input and reversed sentence pairs in the tokenizer). Let me know what else can go wrong!

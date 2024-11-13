---
title: "Installing AutoSklearn with conda"
date: 2024-11-13T15:41:07+08:00
categories:
  - Blog
tags:
  - Machine Learning
  - Python
---

I really wanted to try out the examples of using AutoSklearn over at [Machine Learning Mastery](https://machinelearningmastery.com/automl-libraries-for-python/).
But when I ran `pip install auto-sklearn`, an error occurred:

```
Cython.Compiler.Errors.CompileError: sklearn/ensemble/_hist_gradient_boosting/splitting.pyx
```

Looking into [this issue](https://github.com/scikit-learn/scikit-learn/issues/26858)
suggests a possible incompatibility between an older version of scikit-learn (required by AutoSklearn) and newer Cython (currently Cython-3.0.11 in Slackware).
At the time of writing, AutoSklearn was last updated on Sep 20, 2022 ([see here](https://pypi.org/project/auto-sklearn/)).
Therefore, making it work likely requires older versions of several packages, and perhaps even Python itself.

This is what finally pushed me to figure out how to install and set up a Python virtual environment.
And not just any virtual environment, but conda, a *virtual environment manager*, which handles not only Python packages but Python itself!
According to David Cañones at WhiteBox, "[the conda dependency resolver is more robust](https://www.whiteboxml.com/blog/the-definitive-guide-to-python-virtual-environments-with-conda)" than pip.
This sounds like it could make life a lot easier!

I recommend reading the whole guide in the last link.
In a nutshell, here's what I did:

- To install conda, download and run `https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh`.
- Run `source ~/.bashrc` (the guide above suggests opening a new terminal window) and confirmed that conda was initialized by seeing that my shell prompt started with `(base)`.
- Run these commands:

```
conda create -n automl
conda activate automl
conda install conda-forge::auto-sklearn
```

That's it!

Note that I **did not** run `conda install python` because that installs the latest Python,
and I did't want to spend time figuring out what version of Python is compatible with AutoSklearn from 2022.
That single `conda install` command automaticaly figured out that it needs python-3.9.20, among lots of other dependencies.
I think that's a good example of robust dependency resolution!

And yes, I ran the AutoSklearn example at Machine Learning Mastery and got some nice results.

```
>>> print(model.sprint_statistics())
auto-sklearn results:
  Dataset name: b1aa9d5c-a18f-11ef-a3d0-5c5f67894b53
  Metric: accuracy
  Best validation score: 0.956522
  Number of target algorithm runs: 85
  Number of successful target algorithm runs: 55
  Number of crashed target algorithm runs: 30
  Number of target algorithms that exceeded the time limit: 0
  Number of target algorithms that exceeded the memory limit: 0
```

Enjoy!

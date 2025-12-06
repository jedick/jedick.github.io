---
layout: single
permalink: /noteworthy-differences/
title: Noteworthy Differences
subtitle: AI alignment for detecting meaningful changes
---

### AI alignment for detecting meaningful changes

[![GitHub commit activity](https://img.shields.io/github/commit-activity/t/jedick/noteworthy-differences?logo=github)](https://github.com/jedick/noteworthy-differences)
[![Open in Spaces](https://huggingface.co/datasets/huggingface/badges/resolve/main/open-in-hf-spaces-md.svg)](https://huggingface.co/spaces/jedick/noteworthy-differences)

<a href="https://huggingface.co/spaces/jedick/noteworthy-differences">
<img src="/assets/siteimages/noteworthy-differences_banner.png" alt="Noteworthy Differences banner" style="width:35%; float:right; margin-left:20px;"/>
</a>

**The challenge**: Documents are constantly updated, but users only want notifications for significant changes. Training AI systems to detect what humans consider noteworthy requires careful alignment.

**The solution**: A two-stage AI alignment pipeline that combines classifier disagreement detection with human-in-the-loop annotation to create aligned AI judges.

**Technical achievements**:
- **Two-stage architecture** with classifiers and judge models for robust change detection
- **Disagreement-based annotation** focusing human effort on hard examples (only 8-9% of cases)
- **16% improvement in test accuracy** with heuristic-aligned judge vs unaligned baseline
- **Confidence estimation** based on agreement levels among classifiers and judge
- **Production-ready Gradio interface** for real-time noteworthy difference detection

<div style="clear:both;"></div>


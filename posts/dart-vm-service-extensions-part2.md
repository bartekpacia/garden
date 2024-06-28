---
date: 20240427
---

# Writing a custom Dart VM service extension (part 2)

In this post, I'll take a closer look at Dart VM's service extensions mechanism
and explain what service extensions are and why they are useful in certain
situations. I'll also show how to implement one.

# Service extension running in the Flutter app

Let's get our hands dirty again by implementing a counter app that will share
its state over service extension!

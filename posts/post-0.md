---
date: 20050402
---

This is a post to test out the blog.

# This is h1

## This is h2

### This is h3

This is some code:

```
$ ls | grep .html
footer.html
header.html
index.html
post-1.html
```

And some Dart code:

```dart
var printCount = 0;

void main() {
  () async {
    while (true) {
      await Future.delayed(Duration(seconds: 1));
      printCount++;
      print('Count: $printCount');
    }
  }();
}

// the following line has 80 characters
print('1234567890123456789012345678901234567890123456789012345678901234567890');
```

This is git diff:

```diff
diff --git a/code.css b/code.css
index ebd4525..7d95b95 100644
--- a/code.css
+++ b/code.css
@@ -1,6 +1,8 @@
 /* This file is mostly copied from
 https://github.com/jez/pandoc-markdown-css-theme */

+/* Only place styles for pre, code, and span elements in this file. */
+
 :root {
   --solarized-base03: #002b36;
```

> This is a blockquote With some code in it:
>
> ```bash
> $ printf "%s\n" "Hello, world!"
> ```

This is a list:

- first
- second
- third

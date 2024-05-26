# garden

My personal ~~blog~~ digital garden website.

## Some random notes

Easily see what pandoc produces:

```console
pandoc posts/my-journey-to-google-io-2024.md | prettier --parser html | bat -l html
```

Set correct date (for example to March 13th, 2020 at 21:37):

```console
touch -t 202003132137 posts/post-1.md
```

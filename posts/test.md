---
date: 2026-04-24
title: Example
---

# Example Blog Post
This is an example blog post to show what features have currently been added to the site.

Code blocks can be rendered:
```custom;lang=gleam;id=main;title=Some nice Gleam code
let text =
  children
  |> list.map(element.to_string)
  |> string.join("")
  |> shiki.unescape_text()
  |> string.trim_end()
  |> string.split("")
```

```custom;lang=gleam;id=second;opts=option one|option two
fn run() {
  use k <- result.try(perform_operation())
  Ok(k + 1)
}
@@@new@@@
fn run() {
  result.try(perform_operation(), fn(k) {
    Ok(k + 1)
  })
}
```

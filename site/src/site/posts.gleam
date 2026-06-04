import gleam/time/calendar

pub type Post {
  Post(title: String, contents: String, tags: List(String), date: calendar.Date)
}

pub fn get_posts() -> List(#(String, Post)) {
  [
    #(
      "test",
      Post(
        "Hi there",
        "# Heyyy
```custom;lang=ts;id=main;opts=first|second
const hello = \"world\"
@@@new@@@
let hello = \"world\"
```

```ansi
[0;32mcolored foreground [0m
 [0;42mcolored background [0m

 [0;1mbold text [0m
 [0;2mdimmed text [0m
 [0;4munderlined text [0m
 [0;7mreversed text [0m
 [0;9mstrikethrough text [0m
 [0;4;9munderlined + strikethrough text [0m
```",
        [],
        calendar.Date(2026, calendar.April, 24),
      ),
    ),
  ]
}

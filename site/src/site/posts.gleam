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
```",
        [],
        calendar.Date(2026, calendar.April, 24),
      ),
    ),
  ]
}

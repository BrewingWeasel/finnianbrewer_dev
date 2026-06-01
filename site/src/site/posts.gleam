import gleam/time/calendar

pub type Post {
  Post(title: String, contents: String, tags: List(String), date: calendar.Date)
}

pub fn get_posts() -> List(#(String, Post)) {
  []
}

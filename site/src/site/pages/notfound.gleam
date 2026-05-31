import lustre/attribute
import lustre/element
import lustre/element/html

pub fn view() {
  html.div([], [
    html.h1(
      [
        attribute.class(
          "pt-10 pl-10 text-3xl text-dark dark:text-light font-bold",
        ),
      ],
      [
        element.text("404 Not Found"),
      ],
    ),
    html.a(
      [
        attribute.href("/"),
        attribute.class("text-xl px-10 text-dark-2 dark:text-light-2"),
      ],
      [
        element.text("Go Home"),
      ],
    ),
  ])
}

import ethereal
import gleam/dynamic/decode
import gleam/int
import gleam/list
import gleam/option.{type Option, Some}
import gleam/time/calendar
import javascript/mutable_reference.{type MutableReference}
import lustre/attribute
import lustre/effect
import lustre/element
import lustre/element/html
import lustre/event
import site/components/bars_animation
import site/components/icon
import site/posts

pub type Model {
  Model(mouse_coords: MutableReference(Option(#(Int, Int))), page: Page)
}

pub type Page {
  Home
  Projects
  Blog
}

pub fn new(page: Page) -> #(Model, effect.Effect(Msg)) {
  #(
    Model(mouse_coords: mutable_reference.new(option.None), page:),
    effect.after_paint(fn(dispatch, _) { dispatch(StartAnimation) }),
  )
}

pub type Msg {
  StartAnimation
  MouseMoved(Int, Int)
}

pub fn update(model: Model, message: Msg) -> #(Model, effect.Effect(Msg)) {
  case message {
    StartAnimation -> #(
      model,
      ethereal.init_animation("canvas", bars_animation.draw(model.mouse_coords)),
    )
    MouseMoved(x, y) -> {
      mutable_reference.set(model.mouse_coords, echo Some(#(x, y)))
      #(model, effect.none())
    }
  }
}

pub fn icon(icon, label, link) {
  html.a(
    [
      attribute.href(link),
      attribute.class(
        "bg-dark/10 dark:bg-dark-0-5 p-2 rounded-lg text-dark dark:text-light hover:scale-110 transition-transform ease-in-out duration-200",
      ),
      attribute.attribute("aria-label", label),
      attribute.attribute("target", "_blank"),
      attribute.attribute("rel", "noopener noreferrer"),
    ],
    [
      icon(),
    ],
  )
}

pub fn view(model: Model) -> element.Element(Msg) {
  let #(contents, mobile_classes) = case model.page {
    Home -> #(homepage(), "")
    Projects -> #(projects(), "max-md:hidden")
    Blog -> #(blog(), "max-md:hidden")
  }
  html.div(
    [
      attribute.class("bg-light dark:bg-dark w-screen h-screen flex"),
    ],
    [
      html.canvas([
        attribute.id("canvas"),
        attribute.class(
          "block fixed right-0 transform-[scaleX(-1)] md:top-0 bottom-0 md:bottom-auto max-md:translate-y-1/5 max-md:transform-[scale(-1.0)] z-0 max-md:pointer-events-none "
          <> mobile_classes,
        ),
        attribute.width(700),
        attribute.height(1200),
        event.on("mousemove", {
          use x <- decode.field("offsetX", decode.int)
          use y <- decode.field("offsetY", decode.int)

          decode.success(MouseMoved(x, y))
        }),
      ]),
      ..contents
    ],
  )
}

fn homepage() {
  [
    html.div(
      [
        attribute.class(
          "min-h-dvh w-full flex items-start justify-center px-5 pt-16 pb-12 sm:items-center sm:justify-start sm:px-10 sm:py-12 md:px-16 lg:px-30",
        ),
      ],
      [
        html.div(
          [attribute.class("flex flex-col items-center gap-1 sm:ml-30")],
          [
            html.div(
              [
                attribute.class(
                  "flex flex-wrap items-center justify-center gap-2 sm:justify-start z-10",
                ),
              ],
              [
                html.h1(
                  [
                    attribute.class(
                      "w-full text-4xl font-bold text-center sm:text-left text-dark dark:text-light sm:w-auto sm:mr-4",
                    ),
                  ],
                  [
                    html.text("Finnian Brewer"),
                  ],
                ),
                icon(icon.github, "GitHub", "https://github.com/brewingweasel"),
                icon(
                  icon.linkedin,
                  "LinkedIn",
                  "https://www.linkedin.com/in/finnian-brewer-208b162b5",
                ),
                icon(icon.resume, "Resume", "https://resume.finnianbrewer.dev/"),
              ],
            ),
            html.hr([
              attribute.class("w-full border-t-2 border-dark dark:border-light"),
            ]),
            html.p(
              [
                attribute.class(
                  "max-w-102 text-center text-dark dark:text-light sm:text-left z-10",
                ),
              ],
              [
                element.text("Computer Science & Religious Studies at "),
                html.span([attribute.class("text-orange font-semibold")], [
                  element.text("Oregon State"),
                ]),
                element.text("."),
                html.br([]),
                element.text(
                  "Fan of functional programming, language learning, PLT, and backpacking.",
                ),
              ],
            ),
            html.div(
              [
                attribute.class(
                  "flex flex-wrap gap-6 items-center w-full p-1 justify-center sm:justify-end z-10",
                ),
              ],
              [
                html.a(
                  [
                    attribute.href("/projects"),
                    attribute.class(
                      "text-dark-2 dark:text-light-2 hover:underline",
                    ),
                  ],
                  [
                    html.text("/projects"),
                  ],
                ),
                html.a(
                  [
                    attribute.href("/blog"),
                    attribute.class(
                      "text-dark-2 dark:text-light-2 hover:underline",
                    ),
                  ],
                  [
                    html.text("/blog"),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ]
}

fn projects() {
  [
    html.div(
      [
        attribute.class(
          "bg-light dark:bg-dark min-h-full w-full flex flex-col gap-3 px-5 py-12 sm:px-10 md:px-16 lg:ml-44 lg:mt-30 lg:px-0 lg:py-0",
        ),
      ],
      [
        html.nav(
          [
            attribute.class(
              "flex items-center gap-2 text-sm text-dark-2 dark:text-light-2",
            ),
            attribute.attribute("aria-label", "Breadcrumb"),
          ],
          [
            html.a(
              [
                attribute.href("/"),
                attribute.class("hover:underline"),
              ],
              [html.text("Home")],
            ),
            html.span([attribute.class("text-dark-3 dark:text-light-3")], [
              html.text("/"),
            ]),
            html.span([attribute.class("text-dark dark:text-light")], [
              html.text("Projects"),
            ]),
          ],
        ),
        html.h1(
          [
            attribute.class(
              "text-4xl font-bold text-left text-dark dark:text-light",
            ),
          ],
          [
            html.text("Projects"),
          ],
        ),
        project(
          "Gleamgen",
          "Intelligent and type-safe Gleam codegen library.",
          [
            #(icon.book(), "https://gleamgen.hexdocs.pm/"),
            #(icon.git(), "https://github.com/brewingweasel/gleamgen"),
          ],
          ["Gleam"],
        ),
        project(
          "Lilac",
          "String manipulation language based on pattern matching and recursion.",
          [
            #(icon.git(), "https://github.com/brewingweasel/lilac"),
          ],
          ["OCaml", "PLT"],
        ),
        project(
          "helpmyfriendcantdraw",
          "Concurrent multiplayer drawing website made with Gleam and OTP.",
          [
            #(icon.globe(), "https://helpmyfriendcantdraw.fly.dev"),
            #(icon.git(), "https://git.com/brewingweasel/helpmyfriendcantdraw"),
          ],
          ["Gleam", "Erlang"],
        ),
        project(
          "Kalba Reader",
          "Desktop sentence mining and language learning application with a focus on extensibility and Anki integration.",
          [
            #(icon.git(), "https://github.com/brewingweasel/Kalba"),
          ],
          ["Rust", "Tauri", "Vue.js"],
        ),
        project(
          "Shush",
          "An experiment of creating a typed language that compiles to POSIX sh.",
          [
            #(icon.git(), "https://github.com/brewingweasel/shelltranspiler"),
          ],
          ["Rust", "PLT"],
        ),
      ],
    ),
  ]
}

fn blog() {
  let posts =
    posts.get_posts()
    |> list.sort(by: fn(first, second) {
      calendar.naive_date_compare(first.1.date, second.1.date)
    })
    |> list.map(fn(post) { post_link(post.0, post.1) })

  [
    html.div(
      [
        attribute.class(
          "bg-light dark:bg-dark min-h-full w-full flex flex-col gap-3 px-5 py-12 sm:px-10 md:px-16 lg:ml-44 lg:mt-30 lg:px-0 lg:py-0",
        ),
      ],
      [
        html.nav(
          [
            attribute.class(
              "flex items-center gap-2 text-sm text-dark-2 dark:text-light-2",
            ),
            attribute.attribute("aria-label", "Breadcrumb"),
          ],
          [
            html.a(
              [
                attribute.href("/"),
                attribute.class("hover:underline"),
              ],
              [html.text("Home")],
            ),
            html.span([attribute.class("text-dark-3 dark:text-light-3")], [
              html.text("/"),
            ]),
            html.span([attribute.class("text-dark dark:text-light")], [
              html.text("Blog"),
            ]),
          ],
        ),
        html.h1(
          [
            attribute.class(
              "text-4xl font-bold text-left text-dark dark:text-light",
            ),
          ],
          [
            html.text("Blog"),
          ],
        ),
        ..posts
      ],
    ),
  ]
}

fn post_link(slug, post: posts.Post) {
  let date_text =
    calendar.month_to_string(post.date.month)
    <> " "
    <> int.to_string(post.date.day)
    <> ", "
    <> int.to_string(post.date.year)

  html.a(
    [
      attribute.href("/blog/" <> slug),
      attribute.class(
        "block w-full max-w-120 text-dark dark:text-light bg-light-2 dark:bg-dark-0-5 px-4 py-3 rounded-lg hover:bg-light-3 dark:hover:bg-dark-2 transition-colors",
      ),
    ],
    [
      html.h2([attribute.class("text-xl font-semibold")], [
        html.text(post.title),
      ]),
      html.p([attribute.class("text-sm text-dark-2 dark:text-light-2")], [
        html.text(date_text),
      ]),
    ],
  )
}

fn project(name: String, description: String, links, tags) {
  let icons =
    links
    |> list.map(fn(pair) {
      let #(icon, address) = pair
      html.a(
        [
          attribute.class(
            "text-dark-3 dark:text-light-2 hover:scale-110 transition-transform ease-in-out duration-150",
          ),
          attribute.href(address),
          attribute.target("_blank"),
        ],
        [icon],
      )
    })

  let tags =
    tags
    |> list.map(fn(tag) {
      html.span(
        [
          attribute.class("text-xs bg-dark-3 text-light px-2 py-1 rounded-lg"),
        ],
        [html.text(tag)],
      )
    })

  html.div(
    [
      attribute.class(
        "bg-light-2 dark:bg-dark-0-5 py-4 px-4 rounded-lg text-dark dark:text-light w-full max-w-120",
      ),
    ],
    [
      html.div([attribute.class("flex w-full justify-between gap-3")], [
        html.h2(
          [
            attribute.class(
              "min-w-0 break-words text-2xl font-semibold text-dark-2 dark:text-light-3",
            ),
          ],
          [
            html.text(name),
          ],
        ),
        html.div([attribute.class("flex shrink-0 gap-3")], icons),
      ]),
      html.p([], [
        html.text(description),
      ]),
      html.div(
        [attribute.class("flex flex-wrap gap-2 w-full mt-1 justify-end")],
        tags,
      ),
    ],
  )
}

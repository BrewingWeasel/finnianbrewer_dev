import ethereal
import gleam/dynamic/decode
import gleam/option.{type Option, Some}
import javascript/mutable_reference.{type MutableReference}
import lustre/attribute
import lustre/effect
import lustre/element
import lustre/element/html
import lustre/event
import site/components/bars_animation
import site/components/icon

pub type Model {
  Model(mouse_coords: MutableReference(Option(#(Int, Int))))
}

pub fn new() -> #(Model, effect.Effect(Msg)) {
  #(
    Model(mouse_coords: mutable_reference.new(option.None)),
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
      mutable_reference.set(model.mouse_coords, Some(#(x, y)))
      #(model, effect.none())
    }
  }
}

pub fn icon(icon, label, link) {
  html.a(
    [
      attribute.href(link),
      attribute.class(
        "bg-dark/10 dark:bg-light/10 p-2 rounded-lg text-dark dark:text-light hover:scale-110 transition-transform ease-in-out duration-200",
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

pub fn view(_model: Model) -> element.Element(Msg) {
  html.div([], [
    html.canvas([
      attribute.id("canvas"),
      attribute.class("fixed top-0 right-0"),
      attribute.width(700),
      attribute.height(1200),
      attribute.style("transform", "scaleX(-1)"),
      event.on("mousemove", {
        use x <- decode.field("offsetX", decode.int)
        use y <- decode.field("offsetY", decode.int)

        decode.success(MouseMoved(x, y))
      }),
    ]),
    html.div(
      [
        attribute.class(
          "bg-light dark:bg-dark w-screen h-screen flex items-center",
        ),
      ],
      [
        html.div([attribute.class("flex flex-col items-center gap-1 ml-30")], [
          html.div([attribute.class("flex gap-2")], [
            html.h1(
              [
                attribute.class(
                  "text-4xl font-bold text-center text-dark dark:text-light mr-4",
                ),
              ],
              [
                html.text("Finnian Brewer"),
              ],
            ),
            icon(icon.github, "GitHub", "https://github.com/brewingweasel"),
            icon(icon.linkedin, "LinkedIn", ""),
            icon(icon.resume, "Resume", ""),
          ]),
          html.hr([
            attribute.class("w-full border-t-2 border-dark dark:border-light"),
          ]),
          html.p(
            [
              attribute.class("max-w-102 text-left text-dark dark:text-light"),
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
              // element.text(
            //   "Hello! I'm a first-year at Oregon State University majoring in Computer Science and Religious Studies. My interests include functional programming, running, language learning, programming language theory, and backpacking.",
            // ),
            ],
          ),
          html.div(
            [
              attribute.class("flex gap-6 items-center w-full p-1 justify-end"),
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
        ]),
      ],
    ),
  ])
}

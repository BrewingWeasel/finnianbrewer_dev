import gleam/option
import lustre/attribute
import lustre/effect
import lustre/element
import lustre/element/html
import maud
import maud/components
import mork
import site/posts
import site/shiki

pub type Model {
  Model(slug: String, post: posts.Post)
}

pub fn new(slug, post) -> #(Model, effect.Effect(Msg)) {
  #(Model(slug, post), highlight_code_blocks())
}

pub type Msg

pub fn update(model: Model, _message: Msg) -> #(Model, effect.Effect(Msg)) {
  #(model, effect.none())
}

fn highlight_code_blocks() -> effect.Effect(Msg) {
  effect.after_paint(fn(_dispatch, root) { shiki.highlight_code_blocks(root) })
}

pub fn view(model: Model) -> element.Element(Msg) {
  let components =
    components.default()
    |> components.h3(fn(id, text) {
      html.h3(
        [
          attribute.id(id),
          attribute.class(
            "text-2xl my-2 font-bold text-dark-2 dark:text-light-2",
          ),
        ],
        text,
      )
    })
    |> components.code(fn(language, children) {
      case language {
        option.Some(lang) ->
          html.code(
            [
              attribute.class("language-" <> lang),
              attribute.attribute("data-language", lang),
            ],
            children,
          )
        option.None ->
          html.code(
            [
              attribute.class(
                "rounded-sm bg-dark/10 dark:bg-light/10 px-1 py-0.5",
              ),
            ],
            children,
          )
      }
    })
    |> components.pre(fn(children) {
      html.pre([attribute.class("blog-code-block")], children)
    })
    |> components.p(fn(text) { html.p([attribute.class("my-2")], text) })

  html.div(
    [
      attribute.class(
        "min-h-dvh w-full flex flex-col items-center bg-light dark:bg-dark px-5 py-10 sm:px-8",
      ),
    ],
    [
      html.div([attribute.class("w-full max-w-180")], [
        html.nav(
          [
            attribute.class(
              "mb-4 flex items-center gap-2 text-sm text-dark-2 dark:text-light-2",
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
            html.a(
              [
                attribute.href("/blog"),
                attribute.class("hover:underline"),
              ],
              [html.text("Blog")],
            ),
            html.span([attribute.class("text-dark-3 dark:text-light-3")], [
              html.text("/"),
            ]),
            html.span([attribute.class("text-dark dark:text-light")], [
              html.text(model.slug),
            ]),
          ],
        ),
        html.div(
          [
            attribute.class("text-dark dark:text-light w-full"),
          ],
          maud.render_markdown(
            model.post.contents,
            mork.configure(),
            components,
          ),
        ),
      ]),
    ],
  )
}

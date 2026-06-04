import gleam/bool
import gleam/dict
import gleam/int
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import lustre/attribute
import lustre/effect
import lustre/element
import lustre/element/html
import lustre/event
import maud
import maud/components
import mork
import site/posts
import site/shiki

pub type Model {
  Model(slug: String, post: posts.Post, selected_blocks: dict.Dict(String, Int))
}

pub fn new(slug, post) -> #(Model, effect.Effect(Msg)) {
  #(Model(slug, post, dict.new()), highlight_code_blocks())
}

pub type Msg {
  SwapCode(String, Int, String, String)
}

pub fn update(model: Model, message: Msg) -> #(Model, effect.Effect(Msg)) {
  case message {
    SwapCode(id, version, code, language) -> {
      #(model, move_code_block(id, code, language, version))
    }
  }
}

fn highlight_code_blocks() -> effect.Effect(Msg) {
  effect.after_paint(fn(_dispatch, root) { shiki.highlight_code_blocks(root) })
}

fn move_code_block(
  id: String,
  code: String,
  language: String,
  version: Int,
) -> effect.Effect(Msg) {
  effect.after_paint(fn(_dispatch, _root) {
    shiki.move_code_block(id, code, language, version)
  })
}

fn get_at(list: List(String), index: Int) -> Result(String, Nil) {
  list
  |> list.drop(index)
  |> list.first()
}

fn codeblock(
  _model: Model,
  language: String,
  children: List(element.Element(Msg)),
) -> element.Element(Msg) {
  case language {
    "custom;" <> rest -> {
      let attributes =
        string.split(rest, ";")
        |> list.map(fn(attr) {
          case string.split_once(attr, "=") {
            Ok(#(key, value)) -> #(key, value)
            _ -> #(attr, attr)
          }
        })
        |> dict.from_list()

      let lang = dict.get(attributes, "lang") |> result.unwrap(rest)
      let id = case dict.get(attributes, "id") {
        Ok(id) -> id
        Error(Nil) -> rest
      }

      let text =
        children
        |> list.map(element.to_string)
        |> string.join("")
        |> shiki.unescape_text()
        |> string.trim_end()
        |> string.split("\n@@@new@@@\n")

      let options =
        dict.get(attributes, "opts") |> result.unwrap("") |> string.split("|")

      let selected_text =
        get_at(text, 0)
        |> result.unwrap("")

      let active_button_class =
        "px-3 py-1 text-light grow bg-dark-2 dark:bg-light-2 dark:text-dark rounded-t-lg"

      let inactive_button_class =
        "px-3 py-1 text-light grow bg-dark-3 dark:bg-light-3 dark:text-dark rounded-t-lg cursor-pointer"

      let switch_option_buttons =
        list.index_map(options, fn(option, i) {
          let next_text =
            get_at(text, i)
            |> result.unwrap("")

          html.button(
            [
              event.on_click(SwapCode(id, i, next_text, lang)),
              attribute.attribute("data-magic-move-option", int.to_string(i)),
              attribute.attribute("data-active-class", active_button_class),
              attribute.attribute("data-inactive-class", inactive_button_class),
              attribute.aria_pressed(bool.to_string(i == 0)),
              attribute.class(case i == 0 {
                True -> active_button_class
                False -> inactive_button_class
              }),
            ],
            [element.text(option)],
          )
        })

      let #(tool_bar_contents, additional_code_attributes) = case
        dict.get(attributes, "title")
      {
        Ok(title) -> #(
          [
            html.div([attribute.class(active_button_class)], [
              element.text(title),
            ]),
          ],
          [],
        )
        Error(Nil) -> #(switch_option_buttons, [
          attribute.attribute("data-magic-move", "true"),
        ])
      }

      element.fragment([
        html.div(
          [
            attribute.id(id <> "-toolbar"),
            attribute.class("flex items-center gap-0 bg-dark-3 dark:bg-light-3"),
          ],
          tool_bar_contents,
        ),

        html.code(
          [
            attribute.class("language-" <> lang),
            attribute.attribute("data-language", lang),
            attribute.id(id),
            ..additional_code_attributes
          ],
          [element.text(selected_text)],
        ),
      ])
    }
    language ->
      html.code(
        [
          attribute.class("language-" <> language),
          attribute.attribute("data-language", language),
        ],
        children,
      )
  }
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
        option.Some(lang) -> codeblock(model, lang, children)
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

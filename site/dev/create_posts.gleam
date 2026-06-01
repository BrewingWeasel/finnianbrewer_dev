import gleam/int
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import gleam/time/calendar
import gleamgen/expression
import gleamgen/expression/constructor
import gleamgen/function
import gleamgen/import_
import gleamgen/module
import gleamgen/module/definition
import gleamgen/render
import gleamgen/type_
import gleamgen/type_/custom
import gleamgen/type_/variant
import shellout
import simplifile

const posts_file = "src/site/posts.gleam"

pub fn main() {
  let assert Ok(posts) = simplifile.read_directory("../posts")

  let assert Ok(_) =
    posts
    |> list.map(post_from_file)
    |> generate()
    |> render.to_string()
    |> simplifile.write(to: posts_file)

  let _ =
    shellout.command("gleam", with: ["format", posts_file], in: ".", opt: [])

  Nil
}

fn post_from_file(file_name: String) -> PostInfo {
  let assert Ok(contents) = simplifile.read("../posts/" <> file_name)

  let #(properties, contents) = case contents {
    "---\n" <> rest -> {
      let assert Ok(#(props, contents)) = string.split_once(rest, "\n---\n")
      let props =
        props
        |> string.split("\n")
        |> list.map(fn(line) {
          let assert Ok(#(name, value)) = string.split_once(line, ": ")
          #(name, value)
        })

      #(props, string.trim_end(contents))
    }
    _ -> #([], contents)
  }

  PostInfo(string.remove_suffix(file_name, ".md"), properties, contents)
}

type PostInfo {
  PostInfo(
    file_name: String,
    properties: List(#(String, String)),
    contents: String,
  )
}

type ImportedDate =
  custom.CustomType(calendar.Date, #())

type ImportedMonth =
  custom.CustomType(calendar.Month, #())

type PostType =
  custom.CustomType(Nil, #())

fn generate(posts: List(PostInfo)) {
  let mod = {
    use time_mod <- module.with_import(
      import_.new(["gleam", "time", "calendar"]),
    )

    let month_type: type_.GeneratedType(ImportedMonth) =
      custom.to_type(import_.raw_type(time_mod, "Month"))
    let date_type =
      custom.new()
      |> custom.with_variant(fn(_) {
        variant.new("Date")
        |> variant.with_argument(option.Some("year"), type_.int)
        |> variant.with_argument(option.Some("month"), month_type)
        |> variant.with_argument(option.Some("day"), type_.int)
      })

    use date_type, date_constructor <- module.with_imported_custom_type1(
      time_mod,
      "Date",
      date_type,
    )
    let new_date = constructor.to_expression3(date_constructor)

    let post_def = definition.new("Post") |> definition.with_publicity(True)

    let post_type =
      custom.new()
      |> custom.with_variant(fn(_) {
        variant.new("Post")
        |> variant.with_argument(option.Some("title"), type_.string)
        |> variant.with_argument(option.Some("contents"), type_.string)
        |> variant.with_argument(option.Some("tags"), type_.list(type_.string))
        |> variant.with_argument(option.Some("date"), custom.to_type(date_type))
      })

    use post_type: PostType, post_constructor <- module.with_custom_type1(
      post_def,
      post_type,
    )

    let post_constructor = constructor.to_expression4(post_constructor)

    let get_posts_def =
      definition.new("get_posts") |> definition.with_publicity(True)

    use _get_posts <- module.with_function(
      get_posts_def,
      function.new0(
        type_.list(type_.tuple2(type_.string, custom.to_type(post_type))),
        fn() {
          posts
          |> list.map(fn(post) {
            let tags =
              list.key_find(post.properties, "tags")
              |> result.map(string.split(_, ","))
              |> result.unwrap([])
              |> list.map(expression.string)
              |> expression.list

            let title =
              list.key_find(post.properties, "title")
              |> result.unwrap(post.file_name)

            let date = create_date(post.properties, time_mod, new_date)

            expression.tuple2(
              expression.string(post.file_name),
              expression.construct4(
                post_constructor,
                expression.string(title),
                expression.string(post.contents),
                tags,
                date,
              ),
            )
          })
          |> expression.list
        },
      ),
    )
    module.eof()
  }
  module.render(mod, render.default_context())
}

fn create_date(
  properties: List(#(String, String)),
  time_mod,
  new_date: expression.Expression(fn(Int, _, Int) -> ImportedDate),
) -> expression.Expression(ImportedDate) {
  case list.key_find(properties, "date") {
    Ok(date_str) -> {
      let assert [year, month, day] = string.split(date_str, "-")

      let assert Ok(year) = int.parse(year)
      let assert Ok(day) = int.parse(day)
      let assert Ok(month) =
        int.parse(month)
        |> result.try(calendar.month_from_int)
        |> result.map(fn(month) {
          calendar.month_to_string(month) |> import_.raw_ident(time_mod, _)
        })

      expression.construct3(
        new_date,
        expression.int(year),
        month,
        expression.int(day),
      )
    }
    Error(_) -> expression.todo_(option.Some("no date provided"))
  }
}

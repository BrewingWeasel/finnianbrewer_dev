import gleam/json
import lustre/attribute
import lustre/element
import lustre/element/html
import shellout
import simplifile
import site
import site/pages/home

pub fn main() {
  let _ = simplifile.create_directory_all("dist/blog")
  let _ =
    shellout.command(
      "gleam",
      with: ["run", "-m", "lustre/dev", "build"],
      in: ".",
      opt: [],
    )

  let #(home, _effect) = home.new(home.Home)
  render(site.Home(home), site.HydratedHome, "index")

  let #(projects, _effect) = home.new(home.Projects)
  render(site.Home(projects), site.HydratedProjects, "projects")
}

fn render(page, hydrated, location) {
  let assert Ok(_) =
    page
    |> site.view()
    |> page_wrapper(site.hydrated_page_to_json(hydrated))
    |> element.to_string()
    |> prepend_doctype()
    |> simplifile.write(to: "dist/" <> location <> ".html")

  Nil
}

fn prepend_doctype(page: String) -> String {
  "<!DOCTYPE html>\n" <> page
}

fn page_wrapper(contents, model_json) {
  html.html([], [
    html.head([], [
      html.meta([attribute.charset("UTF-8")]),
      html.meta([
        attribute.content("width=device-width, initial-scale=1.0"),
        attribute.name("viewport"),
      ]),
      html.title([], "Finnian Brewer"),
      html.link([
        attribute.href("https://fonts.googleapis.com"),
        attribute.rel("preconnect"),
      ]),
      html.link([
        attribute.attribute("crossorigin", ""),
        attribute.href("https://fonts.gstatic.com"),
        attribute.rel("preconnect"),
      ]),
      html.link([
        attribute.rel("stylesheet"),
        attribute.href(
          "https://fonts.googleapis.com/css2?family=Lato:ital,wght@0,100;0,300;0,400;0,700;0,900;1,100;1,300;1,400;1,700;1,900&display=swap",
        ),
      ]),

      html.link([
        attribute.rel("stylesheet"),
        attribute.href("/site.css"),
      ]),

      html.script(
        [
          attribute.src("/site.js"),
          attribute.type_("module"),
        ],
        "",
      ),
      html.script(
        [
          attribute.type_("application/json"),
          attribute.id("initial-model"),
        ],
        json.to_string(model_json),
      ),
    ]),
    html.body([attribute.class("bg-light dark:bg-dark")], [
      html.div([attribute.id("app")], [contents]),
    ]),
  ])
}

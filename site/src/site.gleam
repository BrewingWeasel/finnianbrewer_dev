import gleam/dynamic/decode
import gleam/json
import gleam/option
import gleam/result
import gleam/uri
import lustre
import lustre/effect
import lustre/element
import modem
import site/pages/home
import site/pages/post

pub fn main() -> Nil {
  let app = lustre.application(init, update, view)

  let hydrated_data =
    retrieve_data()
    |> option.to_result(Nil)
    |> result.try(fn(data) {
      result.map_error(json.parse(data, hydrated_page_decoder()), fn(_) { Nil })
    })
    |> result.unwrap(HydratedHome)

  let assert Ok(_) = lustre.start(app, "#app", hydrated_data)

  Nil
}

@external(javascript, "./site_ffi.mjs", "retrieveData")
fn retrieve_data() -> option.Option(String)

pub type HydratedPage {
  HydratedHome
  HydratedProjects
  HydratedBlogPost
}

pub fn hydrated_page_to_json(hydrated_page: HydratedPage) -> json.Json {
  case hydrated_page {
    HydratedHome -> json.string("hydrated_home")
    HydratedProjects -> json.string("hydrated_projects")
    HydratedBlogPost -> json.string("hydrated_blog_post")
  }
}

pub fn hydrated_page_decoder() -> decode.Decoder(HydratedPage) {
  use variant <- decode.then(decode.string)
  case variant {
    "hydrated_home" -> decode.success(HydratedHome)
    "hydrated_projects" -> decode.success(HydratedProjects)
    "hydrated_blog_post" -> decode.success(HydratedBlogPost)
    _ -> decode.failure(HydratedHome, "HydratedPage")
  }
}

pub type Page {
  Home(home.Model)
  Post(post.Model)
}

pub type Msg {
  HomeMsg(home.Msg)
  PostMsg(post.Msg)
  ChangePage(HydratedPage)
}

fn initialize_contents(hydrated_page: HydratedPage) {
  case hydrated_page {
    HydratedHome -> {
      let #(model, effect) = home.new(home.Home)
      #(Home(model), effect.map(effect, HomeMsg))
    }
    HydratedProjects -> {
      let #(model, effect) = home.new(home.Projects)
      #(Home(model), effect.map(effect, HomeMsg))
    }
    HydratedBlogPost -> {
      let #(model, effect) = post.new()
      #(Post(model), effect.map(effect, PostMsg))
    }
  }
}

fn init(hydrated_page: HydratedPage) -> #(Page, effect.Effect(Msg)) {
  let #(model, effect) = initialize_contents(hydrated_page)
  #(model, effect.batch([modem.init(on_url_change), effect]))
}

fn on_url_change(uri: uri.Uri) -> Msg {
  case uri.path_segments(uri.path) {
    ["projects"] -> ChangePage(HydratedProjects)
    ["post", _] -> ChangePage(HydratedBlogPost)
    _ -> ChangePage(HydratedHome)
  }
}

fn update(page: Page, msg: Msg) -> #(Page, effect.Effect(Msg)) {
  case msg {
    HomeMsg(msg) ->
      case page {
        Home(model) -> {
          let #(new_model, eff) = home.update(model, msg)
          #(Home(new_model), effect.map(eff, HomeMsg))
        }
        _ -> #(page, effect.none())
      }
    PostMsg(msg) ->
      case page {
        Post(model) -> {
          let #(new_model, eff) = post.update(model, msg)
          #(Post(new_model), effect.map(eff, PostMsg))
        }
        _ -> #(page, effect.none())
      }
    ChangePage(hydrated_page) -> initialize_contents(hydrated_page)
  }
}

pub fn view(page: Page) -> element.Element(Msg) {
  case page {
    Home(model) -> home.view(model) |> element.map(HomeMsg)
    Post(model) -> post.view(model) |> element.map(PostMsg)
  }
}

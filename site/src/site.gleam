import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/result
import gleam/uri
import lustre
import lustre/effect
import lustre/element
import modem
import site/pages/home
import site/pages/notfound
import site/pages/post
import site/posts

pub fn main() -> Nil {
  let app = lustre.application(init, update, view)

  let page =
    modem.initial_uri()
    |> result.map(page_at_url)
    |> result.unwrap(HomeUrl)

  // Use if there is ever actually hydrated data beyond just the url
  // let hydrated_data =
  //   retrieve_data()
  //   |> option.to_result(Nil)
  //   |> result.try(fn(data) {
  //     result.map_error(json.parse(data, hydrated_page_decoder()), fn(_) { Nil })
  //   })
  //   |> result.unwrap(HydratedHome)

  let assert Ok(_) = lustre.start(app, "#app", page)

  Nil
}

// @external(javascript, "./site_ffi.mjs", "retrieveData")
// fn retrieve_data() -> option.Option(String)

pub type PageUrl {
  HomeUrl
  ProjectsUrl
  BlogUrl
  BlogPostUrl(String)
  NotFoundUrl
}

pub fn page_url_to_json(hydrated_page: PageUrl) -> json.Json {
  case hydrated_page {
    HomeUrl -> json.string("home")
    ProjectsUrl -> json.string("projects")
    BlogUrl -> json.string("blog")
    BlogPostUrl(slug) -> json.string("blog_post_" <> slug)
    NotFoundUrl -> json.string("not_found")
  }
}

pub fn page_url_decoder() -> decode.Decoder(PageUrl) {
  use variant <- decode.then(decode.string)
  case variant {
    "home" -> decode.success(HomeUrl)
    "projects" -> decode.success(ProjectsUrl)
    "blog" -> decode.success(BlogUrl)
    "blog_post_" <> slug -> decode.success(BlogPostUrl(slug))
    _ -> decode.failure(NotFoundUrl, "HydratedPage")
  }
}

pub type Page {
  Home(home.Model)
  Post(post.Model)
  NotFound
}

pub type Msg {
  HomeMsg(home.Msg)
  PostMsg(post.Msg)
  ChangePage(PageUrl)
}

fn initialize_contents(page: PageUrl) {
  case page {
    HomeUrl -> {
      let #(model, effect) = home.new(home.Home)
      #(Home(model), effect.map(effect, HomeMsg))
    }
    ProjectsUrl -> {
      let #(model, effect) = home.new(home.Projects)
      #(Home(model), effect.map(effect, HomeMsg))
    }
    BlogUrl -> {
      let #(model, effect) = home.new(home.Blog)
      #(Home(model), effect.map(effect, HomeMsg))
    }
    BlogPostUrl(slug) -> {
      let posts = posts.get_posts()
      case list.key_find(posts, slug) {
        Ok(post) -> {
          let #(model, effect) = post.new(slug, post)
          #(Post(model), effect.map(effect, PostMsg))
        }
        Error(Nil) -> #(NotFound, effect.none())
      }
    }
    NotFoundUrl -> {
      #(NotFound, effect.none())
    }
  }
}

fn init(page: PageUrl) -> #(Page, effect.Effect(Msg)) {
  let #(model, effect) = initialize_contents(page)
  #(
    model,
    effect.batch([modem.init(fn(uri) { ChangePage(page_at_url(uri)) }), effect]),
  )
}

fn page_at_url(uri: uri.Uri) -> PageUrl {
  case uri.path_segments(uri.path) {
    [] -> HomeUrl
    ["projects"] -> ProjectsUrl
    ["blog"] -> BlogUrl
    ["blog", slug] -> BlogPostUrl(slug)
    _ -> NotFoundUrl
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
    ChangePage(page) -> initialize_contents(page)
  }
}

pub fn view(page: Page) -> element.Element(Msg) {
  case page {
    Home(model) -> home.view(model) |> element.map(HomeMsg)
    Post(model) -> post.view(model) |> element.map(PostMsg)
    NotFound -> notfound.view()
  }
}

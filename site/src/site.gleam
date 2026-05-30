import lustre
import lustre/effect
import lustre/element
import site/pages/home
import site/pages/post

pub fn main() -> Nil {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}

pub type Page {
  Home(home.Model)
  Post(post.Model)
}

pub type Msg {
  HomeMsg(home.Msg)
  PostMsg(post.Msg)
}

fn init(_nil: Nil) -> #(Page, effect.Effect(Msg)) {
  let #(model, effect) = home.new()
  #(Home(model), effect.map(effect, HomeMsg))
  // let #(model, effect) = post.new()
  // #(Post(model), effect.map(effect, PostMsg))
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
  }
}

fn view(page: Page) -> element.Element(Msg) {
  case page {
    Home(model) -> home.view(model) |> element.map(HomeMsg)
    Post(model) -> post.view(model) |> element.map(PostMsg)
  }
}

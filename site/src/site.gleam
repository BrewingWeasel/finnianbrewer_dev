import lustre
import lustre/effect
import lustre/element
import site/pages/home

pub fn main() -> Nil {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}

pub type Page {
  Home(home.Model)
}

pub type Msg {
  HomeMsg(home.Msg)
}

fn init(_nil: Nil) -> #(Page, effect.Effect(Msg)) {
  let #(model, effect) = home.new()
  #(Home(model), effect.map(effect, HomeMsg))
}

fn update(page: Page, msg: Msg) -> #(Page, effect.Effect(Msg)) {
  case msg {
    HomeMsg(home_msg) ->
      case page {
        Home(model) -> {
          let #(new_model, eff) = home.update(model, home_msg)
          #(Home(new_model), effect.map(eff, HomeMsg))
        }
        // _ -> #(page, effect.none())
      }
  }
}

fn view(page: Page) -> element.Element(Msg) {
  case page {
    Home(model) -> home.view(model) |> element.map(HomeMsg)
  }
}

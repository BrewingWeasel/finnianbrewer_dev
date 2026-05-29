import ethereal/component
import ethereal/value
import ethereal/value/animation
import gleam/float
import gleam/int
import gleam/option
import gleam_community/colour
import javascript/mutable_reference.{type MutableReference}

const num_bars = 90

pub fn draw(mouse_position: MutableReference(option.Option(#(Int, Int)))) {
  int.range(0, num_bars, [], fn(components, index) {
    [generate_component(index, mouse_position), ..components]
  })
}

fn generate_component(
  index: Int,
  mouse_position: MutableReference(option.Option(#(Int, Int))),
) -> component.Component {
  let x_position = { index % { num_bars / 3 } } * 20
  let assert Ok(color) = case index % 5 {
    0 -> colour.from_rgb_hex_string("#544e68")
    1 -> colour.from_rgb_hex_string("#8d697a")
    2 -> colour.from_rgb_hex_string("#d08159")
    3 -> colour.from_rgb_hex_string("#ffaa5e")
    _ -> colour.from_rgb_hex_string("#ffd4a3")
  }
  let width = 40 + int.random(3) * 10
  let size = int.max(200 - index * 9 + int.random(120), 10 + int.random(10))

  let max_size = size + 80
  let random_scaling =
    [
      animation.ease_in_out(animation.transition(size, max_size, 0.8)),
      animation.hold(max_size, 0.4),
      animation.ease_in_out(animation.transition(max_size, size, 0.8)),
      animation.hold(size, 3.4 +. float.random() *. 2.0),
    ]
    |> animation.sequence()
    |> animation.loop()
    |> value.offset_time(float.random() *. 100.0)

  component.rectangle_dynamic(
    value.literal(x_position),
    value.literal(0),
    value.literal(width),
    value.function(fn(context) {
      let mouse_change = case mutable_reference.get(mouse_position) {
        option.Some(#(x, _y)) ->
          int.max(300 - int.absolute_value(x - { x_position + width / 2 }), 0)
          / 6

        option.None -> 0
      }
      size + mouse_change + value.resolve(random_scaling, context)
    }),
  )
  |> component.set_color(value.literal(color))
}

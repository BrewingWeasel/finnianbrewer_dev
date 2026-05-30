import gleam/option
import lustre/attribute
import lustre/effect
import lustre/element
import lustre/element/html
import maud
import maud/components
import mork
import site/shiki

const post = "
By design, Gleam is a simple language. \\_
### A Note on Correctness

### Basic Codegen

### Phantom Types

If you haven't used phantom types before, \\_.

The classic example \\_.

Conveniently, we already have types \\_.

Now, if we wanted to introduce an expression that works across multiple types, we can simply leave it generic:
```gleam
pub fn equals(expression1: Expression(a), expression2: Expression(a)) -> Expression(Bool) {
  EqualsExpression(expression1, expression2)
}
```

However, let's say we're adding a list expression. The function signature is easy enough:
```gleam
pub fn list_expression(inner_expressions: List(Expression(a))) -> Expression(List(a)) {
  ListExpression(inner_expressions)
}
```

However, how can we represent this as a variant of the expression type?
```gleam
pub type Expression(a) {
  // ..
  ListExpression(inner_expressions: List(Expression(??)))
}
```
The inner expressions aren't of type a, because a is \\_.

To make sure the library's end user can't accidentally create \\_.

### Let Declarations and \"Use\" Syntax

Also, everything in gleam is immutable, so we cannot simply update a passed reference.
One option would be to return a tuple with both \\_.

However, this is rather ugly. More importantly, it's also easy to break: if we
move either the declaration or the reference, we could end up generating
invalid code!

```gleam
// Without realizing it, we're referencing a variable that we haven't even declared yet!
```

!!! Note: In real world code-generation, being able to reference variables that we can't confirm have been created can be useful. Gleamgen supports this with `expression.raw`. However, it is a choice you must explicitly *opt into*, not a mistake you can accidentally make.

We need a way to create an isolated context where the variable can be used.
What if we passed an anonymous function that takes a reference to the variable
and returns the rest of the block?
```gleam
// TODO: update
fn with_let_declaration(name: String, value: Expression(a), callback: fn(Expression(a)) -> GleamCode) -> GleamCode

fn generate() -> GleamCode {
  with_let_declaration(\"awesome_number\", int(46), fn(awesome_number_ref) {
    add_ints(awesome_number_ref, int(2))
  })
}
```

Not only does this guarantee that `awesome_number` has been defined before it
is used, it also allows us to define \\_.

However, this solution is rather ugly. If we were to include several
variable declarations, we would need several nested functions.
TODO: code 

This adds significant visual noise and the additional indentation at each level
implies a greater complexity of the overall function. Of course, there is added
complexity for the library, but that should not affect the user, especially as
this is not meant to be highly-optimized code.

As such, the library is currently subtly *discouraging* declaring variables.

To solve this problem, we can use one of Gleam's few elements of syntax sugar:
[use](https://tour.gleam.run/advanced-features/use/).

Use removes indentation by passing all of the code below it into an anonymous function, which is passed as the final argument to the function on the right of the `<-`.
The classic gleam example is with [`result.try`](https://hexdocs.pm/gleam_stdlib/gleam/result.html#try).
CODE

The advantages of the `use` syntax are especially apparent when used with our let declarations:
CODE

In gleamgen, this use pattern also forms the basis for function definitions, constants, and imports.
"

pub type Model {
  Model(text: String)
}

pub fn new() -> #(Model, effect.Effect(Msg)) {
  #(Model(post), highlight_code_blocks())
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
        "flex flex-col items-center justify-center bg-light dark:bg-dark",
      ),
    ],
    [
      html.div([attribute.class("w-180")], [
        html.div(
          [
            attribute.class("text-dark dark:text-light w-full"),
          ],
          maud.render_markdown(model.text, mork.configure(), components),
        ),
      ]),
    ],
  )
}

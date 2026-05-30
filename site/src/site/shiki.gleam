import gleam/dynamic.{type Dynamic}

@external(javascript, "./shiki_ffi.mjs", "highlightCodeBlocks")
pub fn highlight_code_blocks(root: Dynamic) -> Nil

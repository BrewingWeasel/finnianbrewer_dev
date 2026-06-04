import gleam/dynamic.{type Dynamic}

@external(javascript, "./shiki_ffi.mjs", "highlightCodeBlocks")
pub fn highlight_code_blocks(root: Dynamic) -> Nil

@external(javascript, "./shiki_ffi.mjs", "unescapeText")
pub fn unescape_text(text: String) -> String

@external(javascript, "./shiki_ffi.mjs", "moveCodeBlock")
pub fn move_code_block(
  id: String,
  code: String,
  language: String,
  version: Int,
) -> Nil

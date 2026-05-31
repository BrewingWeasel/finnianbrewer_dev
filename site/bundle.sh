bunx @tailwindcss/cli -i ./src/site.css -o ./dist/site.css
gleam build
bun build ./build/dev/javascript/site.dev.js --outfile=./dist/site.js --minify

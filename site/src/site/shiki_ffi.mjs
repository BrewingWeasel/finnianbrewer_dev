import { codeToHtml, createCssVariablesTheme } from "shiki";

const aliases = new Map([
	["console", "shellscript"],
	["js", "javascript"],
	["jsx", "javascript"],
	["sh", "shellscript"],
	["shell", "shellscript"],
	["ts", "typescript"],
	["tsx", "typescript"],
]);

export function highlightCodeBlocks(root) {
	const scope =
		root && typeof root.querySelectorAll === "function" ? root : document;

	for (const code of scope.querySelectorAll(
		"pre code[class*='language-']:not([data-shiki])",
	)) {
		void highlightBlock(code);
	}
}

async function highlightBlock(code) {
	code.dataset.shiki = "pending";

	const pre = code.closest("pre");
	const lang = normaliseLanguage(code.dataset.language || languageClass(code));

	const theme = createCssVariablesTheme({
		name: "css-variables",
		variablePrefix: "--shiki-",
		fontStyle: true,
		variableDefaults: {}
	})

	try {
		const highlighted = await codeToHtml(code.textContent || "", {
			lang,
			theme,
		});
		const template = document.createElement("template");
		template.innerHTML = highlighted.trim();
		const shikiPre = template.content.firstElementChild;

		if (!pre || !shikiPre) {
			code.dataset.shiki = "failed";
			return;
		}

		shikiPre.classList.add("blog-code-block", "shiki-highlighted");
		shikiPre.dataset.language = lang;
		pre.replaceWith(shikiPre);
	} catch (_) {
		code.dataset.shiki = "failed";
	}
}

function languageClass(code) {
	return [...code.classList]
		.find((className) => className.startsWith("language-"))
		?.slice("language-".length);
}

function normaliseLanguage(language) {
	if (!language) return "text";
	const lower = language.toLowerCase();
	return aliases.get(lower) || lower;
}

function prefersDark() {
	return window.matchMedia?.("(prefers-color-scheme: dark)").matches === true;
}

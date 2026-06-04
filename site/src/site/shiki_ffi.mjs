import {
	codeToHtml,
	createCssVariablesTheme,
	createHighlighter,
} from "shiki";
import { codeToKeyedTokens, createMagicMoveMachine } from "shiki-magic-move/core";
import { MagicMoveRenderer } from "shiki-magic-move/renderer";

const aliases = new Map([
	["console", "shellscript"],
	["js", "javascript"],
	["jsx", "javascript"],
	["sh", "shellscript"],
	["shell", "shellscript"],
	["ts", "typescript"],
	["tsx", "typescript"],
]);

const magicBlocks = new Map();
const highlighters = new Map();

const theme = createCssVariablesTheme({
	name: "css-variables",
	variablePrefix: "--shiki-",
	fontStyle: true,
	variableDefaults: {},
});

export function unescapeText(html) {
	const doc = new DOMParser().parseFromString(html, "text/html");
	return doc.documentElement.textContent;
}

export function highlightCodeBlocks(root) {
	const scope =
		root && typeof root.querySelectorAll === "function" ? root : document;

	for (const code of scope.querySelectorAll(
		"pre code[class*='language-']:not([data-shiki])",
	)) {
		if (code.dataset.magicMove === "true") {
			void initialiseMagicBlock(code);
		} else {
			void highlightBlock(code);
		}
	}
}

export function moveCodeBlock(id, nextCode, language, version) {
	const block = magicBlocks.get(id);

	if (block?.container?.isConnected) {
		updateSelectedButton(block.wrapper, version);
		void renderMagicBlock(block, nextCode);
		return;
	} else if (block) {
		magicBlocks.delete(id);
	}

	const code = document.getElementById(id);
	if (code) {
		code.textContent = nextCode;
		code.dataset.language = language;
		void initialiseMagicBlock(code, version);
	}
}

async function highlightBlock(code) {
	code.dataset.shiki = "pending";

	const pre = code.closest("pre");
	const lang = normaliseLanguage(code.dataset.language || languageClass(code));

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

async function initialiseMagicBlock(code, selected = 0) {
	code.dataset.shiki = "pending";

	const sourcePre = code.closest("pre");
	const id = code.id;
	const lang = normaliseLanguage(code.dataset.language || languageClass(code));

	if (!sourcePre || !id) {
		code.dataset.shiki = "failed";
		return;
	}

	try {
		const highlighter = await highlighterFor(lang);
		const rendererPre = document.createElement("pre");
		const wrapper = document.createElement("div");
		const toolbar = document.getElementById("toolbar");
		// const buttons = [...sourcePre.querySelectorAll(":scope > button")];
		const machine = createMagicMoveMachine(
			(value) =>
				codeToKeyedTokens(highlighter, value, {
					lang,
					theme: theme.name,
				}),
			{ enhanceMatching: true, splitTokens: true },
		);
		const renderer = new MagicMoveRenderer(rendererPre, {
			duration: 550,
			easing: "cubic-bezier(.2,0,.2,1)",
			stagger: 8,
		});
		const block = { id, lang, machine, renderer, wrapper, container: rendererPre };

		wrapper.dataset.magicMoveBlock = id;
		wrapper.className =
			"my-4 max-w-full overflow-hidden rounded-lg bg-light-2 dark:bg-dark-2";
		rendererPre.className =
			"shiki-magic-move-container relative m-0 max-w-full overflow-x-auto whitespace-pre p-4 text-[clamp(0.78rem,2.5vw,0.9rem)] leading-relaxed";
		rendererPre.dataset.language = lang;

		wrapper.append(toolbar);
		wrapper.append(rendererPre);
		sourcePre.replaceWith(wrapper);

		magicBlocks.set(id, block);
		updateSelectedButton(wrapper, selected);
		renderer.replace(machine.commit(code.textContent || "").current);
	} catch (error) {
		code.dataset.shiki = "failed";
	}
}

function updateSelectedButton(wrapper, selected) {
	for (const button of wrapper.querySelectorAll("[data-magic-move-option]")) {
		const isSelected = Number(button.dataset.magicMoveOption) === selected;
		button.className = isSelected
			? button.dataset.activeClass
			: button.dataset.inactiveClass;
		button.setAttribute("aria-pressed", String(isSelected));
	}
}

async function renderMagicBlock(block, code) {
	const step = block.machine.commit(code).current;
	await block.renderer.render(step);
}

async function highlighterFor(lang) {
	if (!highlighters.has(lang)) {
		highlighters.set(
			lang,
			createHighlighter({
				langs: [lang],
				themes: [theme],
			}),
		);
	}

	return highlighters.get(lang);
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

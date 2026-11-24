// Defaults for :MdBook, a novel / short story collection layout.
// `# Title` starts a story on a new page, `##` a chapter, `---` is a scene break.
// A line starting with `~` is an attribution (author under a quote): smaller,
// right-aligned, with an em dash in front and an empty line after it.
// Front-matter in a document overrides anything here.
const path = require("path");

// Runs in the page before printing: a line starting with `- ` is dialogue. marked turns it
// into a bullet list, so each top-level list item becomes a paragraph with an em dash in front.
const dialogues = `
for (const ul of Array.from(document.querySelectorAll("ul"))) {
    if (ul.closest("li")) continue; // nested lists stay lists
    const paras = Array.from(ul.children).map((li) => {
        const p = document.createElement("p");
        p.className = "dialogue";
        // loose items wrap their text in <p>, which cannot nest in a <p>
        p.innerHTML = "\\u2014\\u00a0" + li.innerHTML.replace(/<\\/?p>/g, "");
        return p;
    });
    if (paras.length) ul.replaceWith(...paras);
}`;

// Runs in the page before printing: wraps every `~ ...` line of a paragraph.
const attributions = `
for (const p of document.querySelectorAll("p")) {
    const lines = p.innerHTML.split("\\n");
    if (!lines.some((l) => l.trimStart().startsWith("~"))) continue;
    p.innerHTML = lines
        .map((l) => {
            const m = l.match(/^\\s*~\\s*[-\\u2013\\u2014]*\\s*(.*)$/);
            return m ? '<span class="attribution">\\u2014 ' + m[1] + "</span>" : l;
        })
        .join("\\n");
}`;

module.exports = {
    stylesheet: [path.join(__dirname, "book.css")],
    body_class: ["book"],
    script: [{ content: dialogues }, { content: attributions }],
    pdf_options: {
        format: "A5",
        margin: "20mm 18mm 22mm",
        printBackground: true,
        displayHeaderFooter: true,
        headerTemplate: "<span></span>",
        footerTemplate:
            '<div style="width:100%;text-align:center;font-family:serif;font-size:8pt;color:#555">' +
            '<span class="pageNumber"></span></div>',
    },
};

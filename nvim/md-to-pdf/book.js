// Defaults for :MdBook, a novel / short story collection layout.
// `# Title` starts a story on a new page, `##` a chapter, `---` is a scene break.
// Front-matter in a document overrides anything here.
const path = require("path");

module.exports = {
    stylesheet: [path.join(__dirname, "book.css")],
    body_class: ["book"],
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

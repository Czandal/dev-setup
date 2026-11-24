// Defaults for :MdPdf / :MdHtml (see lua/czandal/mdpdf.lua).
// Front-matter in a document overrides anything here, e.g.
//   ---
//   pdf_options: { format: A5, landscape: true }
//   stylesheet: ./my.css
//   ---
const path = require("path");

module.exports = {
    stylesheet: [path.join(__dirname, "style.css")],
    highlight_style: "github",
    pdf_options: {
        format: "A4",
        margin: "22mm 20mm",
        printBackground: true,
    },
};

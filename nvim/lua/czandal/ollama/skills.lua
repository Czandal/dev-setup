-- Skills available under <leader>b (visual mode).
--
-- Fields:
--   name     unique id
--   label    text shown in the picker
--   model    Ollama model name
--   format   optional, "json" forces JSON output from Ollama
--   system   optional system prompt (when the Modelfile does not have one)
--   prompt   optional function(text) -> string, wraps the selected text
--   options  optional Ollama options table (temperature, num_ctx, ...)
--   handler  "review"  -> expects korektor JSON, opens inline diff review
--            "replace" -> replaces the selection with the model output
--            "float"   -> shows the model output in a floating window
return {
    {
        name = "korektor-pl",
        label = "Korekta tekstu (PL) — korektor-pl",
        model = "korektor-pl",
        format = "json",
        handler = "review",
    },
}

-- Telescope konfigurieren
require('telescope').setup{
  defaults = {
    mappings = {
      i = {
        -- Mit j und k die Suche navigieren
        ["<c-h>"] = "which_key",
        ["<c-j>"] = "move_selection_next",
        ["<c-k>"] = "move_selection_previous"
      }
    }
  },
  pickers = {
  },
  extensions = {
    -- Weitere Addons für Telescope im README finden
  }
}

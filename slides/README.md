# Slides (Quarto + revealjs)

This folder contains the slide deck sources. `index.qmd` is a small landing
page that links to each presentation, so adding a new talk never overwrites an
older one.

## Decks

- `index.qmd` — landing page (renders to HTML) with a dropdown + links
- `phuse-sde-2026.qmd` — PHUSE Single Day Event 2026, reformatted for a 30-min
  talk + 10-min Q&A (latest)
- `phuse-connect-2026.qmd` — full long-form Phuse Connect 2026 deck

## Preview locally

From the repository root:

- Preview a single deck: `quarto preview slides/phuse-sde-2026.qmd`
- Render everything: `quarto render slides`

Or from this folder:

- Preview: `quarto preview`
- Render: `quarto render`

Outputs go to `slides/_site/`.

## Adding a new deck

1. Create a new `.qmd` next to the others (copy an existing deck as a starting
   point — they share `_quarto.yml` and `styles.css`).
2. Add a matching `<option>` to the dropdown and a `.deck-card` entry in
   `index.qmd`.

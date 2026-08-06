# Slides (Quarto + revealjs)

Presentation decks for {workr}. These live under `pkgdown/menus/slides/` so the
shared pkgdown pipeline picks them up automatically:

`gsm.utils::build_assets()` renders every `*.qmd` in this folder to
`pkgdown/assets/slides/<name>.html` and adds each one to a **Slides** dropdown in
the pkgdown navbar. Menu entries are ordered by the `index:` field in each deck's
front matter and labelled with its `title:`.

## Decks

| File | `index` | Deck |
|---|---|---|
| `phuse-sde-2026.qmd` | 1 | PHUSE Single Day Event 2026 — 30-min talk + 10-min Q&A |
| `phuse-connect-2026.qmd` | 2 | Phuse Connect 2026 — full-length deck |

## Conventions

- **Format lives in each deck's front matter.** There is deliberately no
  `_quarto.yml` here: each `.qmd` is rendered individually (not as a Quarto
  project), so a project file with an `output-dir` would break the build.
- `embed-resources: true` makes each deck a single self-contained HTML, so
  `styles.css` and everything in `images/` is inlined — nothing extra needs to be
  copied to the site.
- Rendered `.html` files are gitignored; CI regenerates them on every build.

## Adding a deck

1. Add a new `.qmd` here, copying the `format:` block from an existing deck.
2. Give it a distinct `title:` (this becomes the dropdown label) and the next
   `index:` value.

No `_pkgdown.yml` edits are needed — the navbar menu is generated.

## Preview locally

```sh
quarto render pkgdown/menus/slides/phuse-sde-2026.qmd
quarto preview pkgdown/menus/slides/phuse-sde-2026.qmd
```

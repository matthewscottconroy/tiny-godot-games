# Demo Browser

A small Godot project that reads this collection and launches any demo in it.

## Purpose

165 folders is more than anyone browses by `ls`. The root README is the index,
but you cannot run anything from it — you have to notice a name, open a
terminal, and pass a path to Godot. This closes that gap: search the
collection, filter it by concept tag, and press Enter.

It is a tool, not a demo. The tools that walk the collection skip it by name,
so it stays out of the index, the tag pages and the count on the front page.

## Running it

```sh
godot --path browser
```

| Key | Action |
|-----|--------|
| Type | Search names, categories, descriptions and tags |
| Enter | Launch the selected demo |
| Escape | Clear the search |

## How It Works

### It reads the same index everyone else does

The catalogue comes from the root `README.md` — the table rows give the demo
names and descriptions, the `###` headings give the categories. Tags come from
each demo's own `<!-- tags: ... -->` line, written by `tools/build_tags.py`.

Nothing here keeps its own list. A browser with a hand-kept catalogue would
disagree with the index within a week, and the disagreement would be invisible
until someone noticed a demo missing.

### It launches, rather than embedding

Selecting a demo starts a **new Godot process** with `--path`:

```gdscript
OS.create_process(OS.get_executable_path(), ["--path", demo_path])
```

Loading a demo's scene into this project instead would mean merging its
autoloads, its input map and its project settings into this one. The input maps
alone would break several demos, which rebind keys deliberately. A separate
process is what "every folder is standalone" means when you actually try to run
two of them.

### What the suite covers

`tests/test_logic.gd` drives the real catalogue against the real collection, so
a change to the index's shape fails here rather than quietly emptying the list.
It checks that every listed demo is a folder that exists, that search and tag
filters compose rather than replace each other, and that a missing collection
reads as no demos rather than an error.

## Files

| Path | Role |
|------|------|
| `scripts/catalogue.gd` | Reads the collection; pure functions over strings and files |
| `scripts/main.gd` | The window: list, search, tag bar, launch |
| `tests/test_logic.gd` | Drives the catalogue against the real collection |

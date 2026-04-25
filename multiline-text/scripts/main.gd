extends Control

@onready var rich: RichTextLabel = $RichText

func _ready() -> void:
	$Buttons/BasicBtn.pressed.connect(_show_basic)
	$Buttons/ColorsBtn.pressed.connect(_show_colors)
	$Buttons/TableBtn.pressed.connect(_show_table)
	$Buttons/EffectsBtn.pressed.connect(_show_effects)
	$Buttons/MixedBtn.pressed.connect(_show_mixed)
	_show_basic()

func _show_basic() -> void:
	rich.text = """[b]Bold text[/b] is wrapped in [code][b][/code] tags.
[i]Italic text[/i] uses [code][i][/code].
[b][i]Bold and italic[/i][/b] can be combined.
[u]Underline[/u] uses [code][u][/code].
[s]Strikethrough[/s] uses [code][s][/code].

[code]Monospace / code[/code] uses [code][code][/code].

This is a paragraph with [b]inline bold[/b] and [i]inline italic[/i] mixed into regular text. RichTextLabel automatically wraps long lines to fit the container width.

[indent]Indented text uses [code][indent][/code].[/indent]
[center]Centered text uses [code][center][/code].[/center]
[right]Right-aligned with [code][right][/code].[/right]"""

func _show_colors() -> void:
	rich.text = """[color=tomato]Red / Tomato[/color]
[color=cornflower_blue]Cornflower Blue[/color]
[color=sea_green]Sea Green[/color]
[color=gold]Gold[/color]
[color=orchid]Orchid[/color]
[color=orange]Orange[/color]

Hex colors: [color=#ff6b6b]#ff6b6b[/color]  [color=#4ecdc4]#4ecdc4[/color]  [color=#ffe66d]#ffe66d[/color]

[bgcolor=navy][color=white]  Background color with [code][bgcolor][/code]  [/color][/bgcolor]

[fgcolor=gold]Foreground overlay with [code][fgcolor][/code][/fgcolor]"""

func _show_table() -> void:
	rich.text = """[b]Tables[/b] use [code][table=columns][/code]:

[table=3]
[cell][b]Name[/b][/cell][cell][b]HP[/b][/cell][cell][b]ATK[/b][/cell]
[cell][color=sea_green]Goblin[/color][/cell][cell]30[/cell][cell]5[/cell]
[cell][color=cornflower_blue]Knight[/color][/cell][cell]120[/cell][cell]22[/cell]
[cell][color=tomato]Dragon[/color][/cell][cell]500[/cell][cell]80[/cell]
[cell][color=gold]Wizard[/color][/cell][cell]60[/cell][cell]45[/cell]
[/table]

Each [code][cell][/code] is one table cell. Cells fill left-to-right, wrapping after [i]columns[/i] cells."""

func _show_effects() -> void:
	rich.text = """[wave amp=20 freq=3 connected=1]~ Wave effect text ~[/wave]

[shake rate=20 level=4 connected=1]!!! Shake effect !!![/shake]

[tornado radius=8 freq=2 connected=1]( Tornado swirl )[/tornado]

[rainbow freq=0.5 sat=0.8 val=0.8]Rainbow colored text scrolls through hue[/rainbow]

[pulse color=#ffffff freq=1.0 ease=-2.0]Pulsing text fades in and out[/pulse]

[hint=This tooltip appears on hover]Hover over this text to see a tooltip[/hint]

Effects are [b]animated[/b] — they run every frame and require no extra code."""

func _show_mixed() -> void:
	rich.text = """[center][b][color=gold]⚔ Quest Log ⚔[/color][/b][/center]

[b]Active Quests:[/b]

[color=cornflower_blue]■[/color] [b]The Lost Amulet[/b]
[indent]Find the amulet hidden in [color=tomato]Darkwood Forest[/color].
Progress: [color=sea_green]2[/color] / 5 fragments found.[/indent]

[color=gold]■[/color] [b]Dragon's Hoard[/b]
[indent][wave amp=5 freq=2 connected=1]URGENT:[/wave] A dragon has been spotted near the village.
Reward: [color=gold]500 gold[/color] + [color=orchid]Rare weapon[/color][/indent]

[table=2]
[cell][b]Stat[/b][/cell][cell][b]Value[/b][/cell]
[cell]Quests completed[/cell][cell][color=sea_green]12[/color][/cell]
[cell]Quests failed[/cell][cell][color=tomato]3[/color][/cell]
[/table]"""

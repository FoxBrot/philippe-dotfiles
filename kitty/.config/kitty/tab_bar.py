# pill-style tab bar — dark theme (cream active pill)
from kitty.fast_data_types import Screen
from kitty.tab_bar import DrawData, ExtraData, TabBarData, as_rgb

ACTIVE_BG = as_rgb(0xCFC2A6)     # active tab pill (cream)
ACTIVE_FG = as_rgb(0x1E1E2E)     # active tab text
INACTIVE_BG = as_rgb(0x2A2A3C)   # inactive pill
INACTIVE_FG = as_rgb(0x8A8377)   # inactive text


def draw_tab(
    draw_data: DrawData, screen: Screen, tab: TabBarData,
    before: int, max_title_length: int, index: int,
    is_last: bool, extra_data: ExtraData,
) -> int:
    if tab.is_active:
        fg, bg = ACTIVE_FG, ACTIVE_BG
    else:
        fg, bg = INACTIVE_FG, INACTIVE_BG

    screen.cursor.fg, screen.cursor.bg = bg, 0
    screen.draw("")
    screen.cursor.fg, screen.cursor.bg = fg, bg
    screen.draw(f" {index} {tab.title[:max_title_length]} ")
    screen.cursor.fg, screen.cursor.bg = bg, 0
    screen.draw("")
    screen.cursor.bg = 0
    screen.draw(" ")
    return screen.cursor.x

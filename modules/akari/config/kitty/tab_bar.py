import os

from kitty.fast_data_types import Screen
from kitty.tab_bar import DrawData, ExtraData, TabBarData, as_rgb, draw_title as draw_tab_title
from kitty.utils import color_as_int

# Akari Material 3 New-Tab Button tokens (surface-container-high / primary)
NEW_TAB_BTN_BG = 0x3B2529
NEW_TAB_BTN_FG = 0xFFB2BD

HOME = os.path.expanduser('~')


def shorten_path(path: str) -> str:
    """Replace the leading home directory with ~ and trailing slashes."""
    if not path:
        return ''
    if path == HOME:
        return '~'
    if path.startswith(HOME + os.sep):
        return '~' + path[len(HOME):]
    return path.rstrip(os.sep) or os.sep


def draw_title(data) -> str:
    """Tab title template helper ({custom}): show only the working directory."""
    wd = data['tab'].active_wd or data['title']
    return shorten_path(wd)


def draw_tab(
    draw_data: DrawData,
    screen: Screen,
    tab: TabBarData,
    before: int,
    max_tab_length: int,
    index: int,
    is_last: bool,
    extra_data: ExtraData,
) -> int:
    default_bg = as_rgb(color_as_int(draw_data.default_bg))

    # Synthetic "+" new-tab button (tab_id < 0)
    if tab.tab_id < 0:
        if tab.is_active:
            btn_bg = as_rgb(color_as_int(draw_data.active_bg))
            btn_fg = as_rgb(color_as_int(draw_data.active_fg))
        else:
            btn_bg = as_rgb(NEW_TAB_BTN_BG)
            btn_fg = as_rgb(NEW_TAB_BTN_FG)

        screen.cursor.bg = btn_bg
        screen.cursor.fg = btn_fg
        screen.cursor.bold = True
        screen.cursor.italic = False
        label = " + " if max_tab_length >= 3 else "+"
        screen.draw(label[: max(1, max_tab_length)])
        end = max(before, screen.cursor.x - 1)

        screen.cursor.bold = False
        screen.cursor.fg = 0
        if not is_last:
            screen.cursor.bg = default_bg
            screen.draw(" ")
        screen.cursor.bg = 0
        return end

    # Regular tab
    gap = 0 if is_last else 1
    title_budget = max(1, max_tab_length - gap)
    draw_tab_title(draw_data, screen, tab, index, title_budget)

    extra = screen.cursor.x - before - title_budget
    if extra > 0:
        if title_budget >= 4:
            screen.cursor.x = before + title_budget - 2
            screen.draw("… ")
        else:
            screen.cursor.x = before + title_budget - 1
            screen.draw("…")

    end = max(before, screen.cursor.x - 1)
    screen.cursor.bold = False
    screen.cursor.italic = False
    screen.cursor.fg = 0
    if gap:
        screen.cursor.bg = default_bg
        screen.draw(" ")
    screen.cursor.bg = 0
    return end

#include <zephyr/kernel.h>
#include <stdio.h>
#include <string.h>

#include "sleep.h"
#include "../assets/custom_fonts.h"

static bool show_sleep_screen = false;

bool is_sleep_screen_active(void) {
    return show_sleep_screen;
}

void set_sleep_screen_active(bool active) {
    show_sleep_screen = active;
}

void draw_sleep_screen(lv_obj_t *canvas) {
    // Show "Sleep" in small text instead of BLE/USB status
    lv_draw_label_dsc_t label_dsc;
    init_label_dsc(&label_dsc, LVGL_FOREGROUND, &quinquefive_8, LV_TEXT_ALIGN_LEFT);
    lv_canvas_draw_text(canvas, 12, 140, SCREEN_WIDTH-8, &label_dsc, "SLEEP");
}

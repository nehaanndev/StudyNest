# Decoration pack PNG assets

Each room theme has one folder here holding its decoration sprites. The app
catalog (`lib/app/decor/decor_items_<theme>.dart`) already references every
file below — drop the finished PNGs into place and they appear in the shop,
the preview dialog, and the room with no code changes. Until a PNG exists,
the app shows a rarity-tinted icon chip as a graceful stand-in.

## Export requirements

- PNG with a fully transparent background (no white matte).
- 512×512 recommended; the subject centered with its base near the bottom
  edge, since sprites are bottom-anchored on the desk surface.
- Match the existing painterly style in `assets/decor/generated/`
  (warm light, soft edges, no flat outlines).
- Room backgrounds are final — these are overlay objects only.

## Expected files

### cozyCafe
alarm_clock.png, bean_jar.png, book_bundle.png, coffee_grinder.png,
cream_pitcher.png, espresso_cup.png, espresso_machine.png, honey_jar.png,
jazz_records.png, letter_bundle.png, menu_board.png, potted_herb.png,
record_cabinet.png, strawberry_tart.png

### rainyLibrary
candlestick.png, card_catalog.png, fireplace.png, hanging_ivy.png,
inkwell.png, notice_board.png, old_jar.png, parchment_roll.png,
quill_set.png, raven.png, reading_glasses.png, sealed_letter.png,
teacup.png, tome_stack.png

### midnightCity
black_coffee.png, city_frame.png, city_lights.png, city_plant.png,
gaming_mouse.png, laptop_stand.png, led_desk_lamp.png, neon_cup_sign.png,
planner_notebook.png, ramen_cup.png, rooftop_telescope.png,
smart_speaker.png, ultrawide_monitor.png

### gardenMatcha
bamboo_fountain.png, bamboo_whisk.png, bonsai.png, botanist_compass.png,
koi_tray.png, matcha_bowl.png, sakura_bowl.png, sakura_branch.png,
stone_candle.png, stone_lantern.png, tea_scroll.png, tea_set_tray.png,
zen_garden.png

### grandArchive
antique_globe.png, archive_raven.png, bankers_lamp.png,
brass_candlestick.png, brass_telescope.png, cartographer_compass.png,
catalog_cabinet.png, celestial_orrery.png, parchment_bundle.png,
quill_cup.png, teacup_saucer.png, wax_seal_kit.png

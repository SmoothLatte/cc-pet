#!/usr/bin/env python3
"""Generate seven original yellow-pig Lottie animations for cc-pet."""
import json, os

RESOURCES = os.path.join(os.path.dirname(__file__), "..", "CCPet", "Resources")

# --- Colors (original yellow pig palette) ---
HEAD_YELLOW = [1.00, 0.84, 0.05, 1]   # Bright yellow
EAR_YELLOW  = [0.96, 0.76, 0.02, 1]   # Slightly darker yellow for ears
SNOUT_PINK  = [1.00, 0.66, 0.72, 1]   # Pink snout
NOSTRIL     = [0.78, 0.32, 0.42, 1]   # Darker pink nostrils
EYE_BLACK   = [0.10, 0.10, 0.12, 1]   # Black eyes
WHITE       = [1, 1, 1, 1]
STAR_GOLD   = [1, 0.92, 0.30, 1]
SWEAT_BLUE  = [0.55, 0.80, 1, 1]
THOUGHT_GRAY= [0.85, 0.85, 0.88, 1]
EXCLAIM_RED = [0.95, 0.30, 0.35, 1]

# --- Helpers ---
def static(v):
    return {"a": 0, "k": v}

def animated(keyframes):
    return {"a": 1, "k": keyframes}

def kf(t, s, e=None, ix=0.3, iy=1, ox=0.7, oy=0):
    if e is None:
        return {"t": t, "s": s}
    return {
        "t": t, "s": s, "e": e,
        "i": {"x": ix, "y": iy}, "o": {"x": ox, "y": oy}
    }

def kf_multi(t, s, e=None, ix=None, iy=None, ox=None, oy=None):
    if e is None:
        return {"t": t, "s": s}
    ix = ix or [0.3]*3; iy = iy or [1]*3; ox = ox or [0.7]*3; oy = oy or [0]*3
    return {
        "t": t, "s": s, "e": e,
        "i": {"x": ix, "y": iy}, "o": {"x": ox, "y": oy}
    }

def tr(px=0, py=0, sx=100, sy=100, r=0, o=100):
    return {
        "ty": "tr",
        "p": static([px, py]), "a": static([0, 0]),
        "s": static([sx, sy]), "r": static(r), "o": static(o)
    }

def tr_default():
    return tr()

def ellipse_shape(w, h, color, opacity=100):
    return {
        "ty": "gr", "it": [
            {"ty": "el", "p": static([0, 0]), "s": static([w, h])},
            {"ty": "fl", "c": static(color), "o": static(opacity)},
            tr_default()
        ]
    }

def rect_shape(w, h, r, color, opacity=100):
    return {
        "ty": "gr", "it": [
            {"ty": "rc", "p": static([0, 0]), "s": static([w, h]), "r": static(r)},
            {"ty": "fl", "c": static(color), "o": static(opacity)},
            tr_default()
        ]
    }

def path_shape(vertices, in_t, out_t, closed, color, opacity=100, stroke=False, stroke_w=3):
    items = [
        {"ty": "sh", "ks": static({"c": closed, "v": vertices, "i": in_t, "o": out_t})}
    ]
    if stroke:
        items.append({"ty": "st", "c": static(color), "o": static(opacity), "w": static(stroke_w), "lc": 2, "lj": 2})
    else:
        items.append({"ty": "fl", "c": static(color), "o": static(opacity)})
    items.append(tr_default())
    return {"ty": "gr", "it": items}

def make_layer(nm, pos, shapes, op=60, opacity=100, rotation=None, scale=None, position_anim=None, ind=None, parent=None):
    ks = {
        "p": position_anim if position_anim else static([pos[0], pos[1], 0]),
        "s": scale if scale else static([100, 100, 100]),
        "r": rotation if rotation else static(0),
        "o": static(opacity),
        "a": static([0, 0, 0])
    }
    layer = {"ty": 4, "nm": nm, "ip": 0, "op": op, "st": 0, "ks": ks, "shapes": shapes}
    if ind is not None:
        layer["ind"] = ind
    if parent is not None:
        layer["parent"] = parent
    return layer

def make_null(nm, ind, op, pos_anim=None, scale_anim=None, rot_anim=None):
    ks = {
        "p": pos_anim if pos_anim else static([100, 100, 0]),
        "s": scale_anim if scale_anim else static([100, 100, 100]),
        "r": rot_anim if rot_anim else static(0),
        "o": static(0),
        "a": static([100, 100, 0])
    }
    return {"ty": 3, "nm": nm, "ind": ind, "ip": 0, "op": op, "st": 0, "ks": ks}

# --- Pig ear (rounded triangle, softer corners) ---
EAR_VERTS = [[-13, 12], [0, -18], [13, 12]]
EAR_IN    = [[8, 4], [-6, -2], [-4, -6]]
EAR_OUT   = [[4, -6], [6, -2], [-8, 4]]

def ear_shapes():
    return [path_shape(EAR_VERTS, EAR_IN, EAR_OUT, True, EAR_YELLOW)]

# --- Solid round eye ---
def open_eye_layer(name, cx, cy, ew=14, eh=18, op=60):
    return make_layer(name, [cx, cy], [ellipse_shape(ew, eh, EYE_BLACK)], op)

# --- Wink eye: downward curve "︵" stroke ---
def wink_eye_shape(width=20, depth=9, stroke_w=3.5):
    w, d = width / 2, depth
    verts = [[-w, 0], [0, -d], [w, 0]]
    in_t  = [[0, 0], [-w*0.55, 0], [0, 0]]
    out_t = [[w*0.55, 0], [0, 0], [0, 0]]
    return path_shape(verts, in_t, out_t, False, EYE_BLACK, stroke=True, stroke_w=stroke_w)

# --- Closed sleeping eye "‿" ---
def closed_eye_shape(width=18, depth=6, stroke_w=3):
    w, d = width / 2, depth
    verts = [[-w, 0], [0, d], [w, 0]]
    in_t  = [[0, 0], [-w*0.55, 0], [0, 0]]
    out_t = [[w*0.55, 0], [0, 0], [0, 0]]
    return path_shape(verts, in_t, out_t, False, EYE_BLACK, stroke=True, stroke_w=stroke_w)

# --- Snout (pink oval with two nostrils) ---
def snout_layers(op, snout_pos=(100, 122), snout_w=64, snout_h=42,
                 nostril_offset=11, nostril_w=10, nostril_h=14):
    cx, cy = snout_pos
    layers = []
    layers.append(make_layer("left_nostril", [cx - nostril_offset, cy + 1],
                             [ellipse_shape(nostril_w, nostril_h, NOSTRIL)], op))
    layers.append(make_layer("right_nostril", [cx + nostril_offset, cy + 1],
                             [ellipse_shape(nostril_w, nostril_h, NOSTRIL)], op))
    layers.append(make_layer("snout", [cx, cy],
                             [ellipse_shape(snout_w, snout_h, SNOUT_PINK)], op))
    return layers

# --- Base yellow pig (round head + 2 ears at top, awake = open + wink) ---
def base_pig_layers(op, eye_layers_override=None, snout_override=None,
                    ear_rot_l=None, ear_rot_r=None,
                    head_w=140, head_h=128):
    layers = []

    # Eyes (topmost)
    if eye_layers_override:
        layers.extend(eye_layers_override)
    else:
        layers.append(open_eye_layer("left_eye", 76, 92, 14, 18, op))
        layers.append(make_layer("right_eye", [124, 90], [wink_eye_shape(22, 10)], op))

    # Snout
    if snout_override:
        layers.extend(snout_override)
    else:
        layers.extend(snout_layers(op))

    # Head (yellow round body)
    layers.append(make_layer("head", [100, 100],
                             [ellipse_shape(head_w, head_h, HEAD_YELLOW)], op))

    # Ears (behind head, poking up from top)
    layers.append(make_layer("left_ear", [68, 40], ear_shapes(), op,
                             rotation=ear_rot_l or static(-15)))
    layers.append(make_layer("right_ear", [132, 40], ear_shapes(), op,
                             rotation=ear_rot_r or static(15)))

    return layers

def wrap(name, fps, op, layers):
    return {"v": "5.7.4", "fr": fps, "ip": 0, "op": op, "w": 200, "h": 200,
            "nm": name, "assets": [], "layers": layers}

# ===== pet_awake =====
def gen_awake():
    op = 60
    null = make_null("bounce", 0, op,
        pos_anim=animated([
            kf(0, [100,100,0], [100,93,0]),
            kf(15, [100,93,0], [100,107,0], 0.5,1,0.5,0),
            kf(30, [100,107,0], [100,95,0]),
            kf(45, [100,95,0], [100,100,0], 0.4,1,0.6,0),
            kf(60, [100,100,0])
        ]),
        scale_anim=animated([
            kf_multi(0, [100,100,100], [103,97,100]),
            kf_multi(15, [103,97,100], [97,103,100]),
            kf_multi(30, [97,103,100], [101,99,100]),
            kf_multi(45, [101,99,100], [100,100,100]),
            kf_multi(60, [100,100,100])
        ])
    )

    ear_rot_l = animated([
        kf(0, [-15], [-23]), kf(15, [-23], [-10], 0.5,1,0.5,0),
        kf(30, [-10], [-18]), kf(45, [-18], [-15], 0.4,1,0.6,0), kf(60, [-15])
    ])
    ear_rot_r = animated([
        kf(0, [15], [23]), kf(15, [23], [10], 0.5,1,0.5,0),
        kf(30, [10], [18]), kf(45, [18], [15], 0.4,1,0.6,0), kf(60, [15])
    ])

    eyes = [
        open_eye_layer("left_eye", 76, 92, 14, 18, op),
        make_layer("right_eye", [124, 90], [wink_eye_shape(22, 10)], op),
    ]

    pig = base_pig_layers(op, eye_layers_override=eyes,
                          ear_rot_l=ear_rot_l, ear_rot_r=ear_rot_r)
    for i, layer in enumerate(pig):
        layer["ind"] = i + 1
        layer["parent"] = 0

    return wrap("awake", 30, op, [null] + pig)

# ===== pet_sleeping =====
def gen_sleeping():
    op = 90
    null = make_null("breathe", 0, op,
        pos_anim=animated([
            kf(0, [100,100,0], [100,103,0], 0.4,1,0.6,0),
            kf(45, [100,103,0], [100,100,0], 0.4,1,0.6,0),
            kf(90, [100,100,0])
        ]),
        scale_anim=animated([
            kf_multi(0, [100,100,100], [101,99,100]),
            kf_multi(45, [101,99,100], [100,100,100]),
            kf_multi(90, [100,100,100])
        ])
    )

    eyes = [
        make_layer("left_eye", [76, 92], [closed_eye_shape(18, 6)], op),
        make_layer("right_eye", [124, 92], [closed_eye_shape(18, 6)], op),
    ]

    pig = base_pig_layers(op, eye_layers_override=eyes)

    for idx, (x_off, size, delay) in enumerate([(10, 7, 0), (18, 9, 20), (26, 12, 40)]):
        dot = make_layer(f"zzz_{idx}", [0, 0],
            [ellipse_shape(size, size, THOUGHT_GRAY)], op, opacity=80,
            position_anim=animated([
                kf(delay, [135 + x_off, 65, 0], [135 + x_off, 25, 0], 0.4,1,0.6,0),
                kf(delay + 45, [135 + x_off, 25, 0], [135 + x_off, 65, 0], 0.4,1,0.6,0),
                kf(min(delay + 90, op), [135 + x_off, 65, 0])
            ]),
            scale=animated([
                kf_multi(delay, [0,0,100], [100,100,100]),
                kf_multi(delay + 10, [100,100,100], [100,100,100]),
                kf_multi(delay + 40, [100,100,100], [0,0,100]),
                kf_multi(min(delay + 45, op), [0,0,100])
            ]))
        pig.append(dot)

    for i, layer in enumerate(pig):
        layer["ind"] = i + 1
        layer["parent"] = 0

    return wrap("sleeping", 30, op, [null] + pig)

# ===== pet_thinking =====
def gen_thinking():
    op = 75
    null = make_null("tilt", 0, op,
        rot_anim=animated([
            kf(0, [0], [5], 0.4,1,0.6,0),
            kf(25, [5], [-3], 0.4,1,0.6,0),
            kf(50, [-3], [0], 0.4,1,0.6,0),
            kf(75, [0])
        ])
    )

    squint_l = closed_eye_shape(14, 5, 3)
    eyes = [
        make_layer("left_eye", [76, 94], [squint_l], op),
        open_eye_layer("right_eye", 124, 88, 14, 18, op),
    ]

    pig = base_pig_layers(op, eye_layers_override=eyes)

    # Three classic thinking bubbles — small → medium → large, ascending
    for idx, (cx, cy, size, delay) in enumerate([(140, 72, 11, 0), (158, 50, 17, 12), (174, 22, 24, 24)]):
        dot = make_layer(f"dot_{idx}", [cx, cy],
            [ellipse_shape(size, size, WHITE)], op, opacity=90,
            scale=animated([
                kf_multi(delay,    [0,0,100], [110,110,100]),
                kf_multi(delay+10, [110,110,100], [95,95,100]),
                kf_multi(delay+22, [95,95,100], [108,108,100]),
                kf_multi(delay+45, [108,108,100], [0,0,100]),
                kf_multi(min(delay+50, op), [0,0,100])
            ]))
        pig.append(dot)

    for i, layer in enumerate(pig):
        layer["ind"] = i + 1
        layer["parent"] = 0

    return wrap("thinking", 30, op, [null] + pig)

# ===== pet_working =====
def gen_working():
    op = 30
    # Body squashes down on each strike — synced with hammer impact frames 7 & 20
    null = make_null("work_bounce", 0, op,
        pos_anim=animated([
            kf(0,  [100,100,0], [100,95,0],  0.4,1,0.6,0),    # 蓄势,微起
            kf(7,  [100,95,0],  [100,110,0], 0.95,1,0.05,0),  # 哐! 急速下震
            kf(10, [100,110,0], [100,98,0],  0.5,1,0.5,0),    # 反弹
            kf(15, [100,98,0],  [100,95,0],  0.4,1,0.6,0),    # 二次蓄势
            kf(20, [100,95,0],  [100,110,0], 0.95,1,0.05,0),  # 哐! 第二次下震
            kf(23, [100,110,0], [100,100,0], 0.5,1,0.5,0),    # 回正
            kf(30, [100,100,0])
        ]),
        scale_anim=animated([
            kf_multi(0,  [100,100,100], [102,98,100]),
            kf_multi(7,  [102,98,100],  [114,86,100]),  # 哐! 压扁
            kf_multi(10, [114,86,100],  [98,102,100]),
            kf_multi(15, [98,102,100],  [102,98,100]),
            kf_multi(20, [102,98,100],  [114,86,100]),  # 哐! 压扁
            kf_multi(23, [114,86,100],  [100,100,100]),
            kf_multi(30, [100,100,100])
        ])
    )

    eyes = [
        open_eye_layer("left_eye", 76, 92, 13, 14, op),
        open_eye_layer("right_eye", 124, 92, 13, 14, op),
    ]

    ear_rot_l = animated([
        kf(0, [-15], [-30], 0.5,1,0.5,0), kf(8, [-30], [0], 0.5,1,0.5,0),
        kf(16, [0], [-26], 0.5,1,0.5,0), kf(24, [-26], [-15], 0.4,1,0.6,0), kf(30, [-15])
    ])
    ear_rot_r = animated([
        kf(0, [15], [30], 0.5,1,0.5,0), kf(8, [30], [0], 0.5,1,0.5,0),
        kf(16, [0], [26], 0.5,1,0.5,0), kf(24, [26], [15], 0.4,1,0.6,0), kf(30, [15])
    ])

    pig = base_pig_layers(op, eye_layers_override=eyes,
                          ear_rot_l=ear_rot_l, ear_rot_r=ear_rot_r)

    # Swinging hammer above the head — clear "working" indicator
    head_color   = [0.50, 0.50, 0.55, 1]   # steel grey
    handle_color = [0.45, 0.28, 0.15, 1]   # wood brown
    # Anchor at handle bottom (0,0); handle goes up, head sits on top.
    hammer_handle = {"ty": "gr", "it": [
        {"ty": "rc", "p": static([0, -24]), "s": static([10, 48]), "r": static(3)},
        {"ty": "fl", "c": static(handle_color), "o": static(100)},
        tr_default()
    ]}
    hammer_head = {"ty": "gr", "it": [
        {"ty": "rc", "p": static([0, -56]), "s": static([42, 24]), "r": static(4)},
        {"ty": "fl", "c": static(head_color), "o": static(100)},
        tr_default()
    ]}
    # Hammer head is drawn above (later in shapes list = top in Lottie)
    hammer_shapes = [hammer_head, hammer_handle]
    # Two strikes per cycle ("哐, 哐") with hard impact pause + bounce
    hammer_rot = animated([
        # ---- 第 1 击 ----
        kf(0,  [-45], [-45], 0.4,1,0.6,0),    # 起手蓄势
        kf(4,  [-45], [25],  0.95,1,0.05,0), # 快速劈下 (4 帧)
        kf(7,  [25],  [25],  0.4,1,0.6,0),    # 撞击停顿 (硬定格)
        kf(10, [25],  [-12], 0.85,1,0.15,0), # 弹起
        # ---- 第 2 击 ----
        kf(13, [-12], [-45], 0.4,1,0.6,0),    # 二次蓄势
        kf(17, [-45], [25],  0.95,1,0.05,0), # 第 2 次劈下
        kf(20, [25],  [25],  0.4,1,0.6,0),    # 撞击停顿
        kf(23, [25],  [-12], 0.85,1,0.15,0), # 弹起
        kf(28, [-12], [-45], 0.4,1,0.6,0),    # 抬回循环起点
        kf(30, [-45])
    ])
    hammer = make_layer("hammer", [150, 80], hammer_shapes, op,
                        opacity=95, rotation=hammer_rot)
    pig.append(hammer)

    # Impact spark: 4-point spike that pops on each strike
    def spike_shape(size, color):
        s = size
        thin = size * 0.18
        verts = [
            [0, -s], [thin, -thin], [s, 0], [thin, thin],
            [0, s], [-thin, thin], [-s, 0], [-thin, -thin]
        ]
        z = [0, 0]
        return path_shape(verts, [z]*8, [z]*8, True, color)

    # Two impact flashes — one per strike
    for idx, strike_frame in enumerate([7, 20]):
        flash = make_layer(f"impact_{idx}", [168, 38],
            [spike_shape(20, [1.0, 0.95, 0.40, 1])], op,
            opacity=100,
            scale=animated([
                kf_multi(max(0, strike_frame - 1), [0,0,100], [180,180,100]),
                kf_multi(strike_frame + 1,        [180,180,100], [60,60,100]),
                kf_multi(strike_frame + 4,        [60,60,100], [0,0,100]),
                kf_multi(min(strike_frame + 5, op), [0,0,100])
            ]),
            rotation=animated([
                kf(max(0, strike_frame - 1), [0], [45]),
                kf(min(strike_frame + 5, op), [45])
            ]))
        pig.append(flash)


    for i, layer in enumerate(pig):
        layer["ind"] = i + 1
        layer["parent"] = 0

    return wrap("working", 30, op, [null] + pig)

# ===== pet_celebrating =====
def gen_celebrating():
    op = 60
    # Bigger jump + body wiggle on top of vertical leap
    null = make_null("jump", 0, op,
        pos_anim=animated([
            kf(0, [100,100,0], [100,55,0], 0.3,1,0.7,0),
            kf(15, [100,55,0], [100,118,0], 0.5,1,0.5,0),
            kf(30, [100,118,0], [100,62,0], 0.4,1,0.6,0),
            kf(45, [100,62,0], [100,100,0], 0.4,1,0.6,0),
            kf(60, [100,100,0])
        ]),
        scale_anim=animated([
            kf_multi(0, [100,100,100], [112,88,100]),
            kf_multi(15, [112,88,100], [88,114,100]),
            kf_multi(30, [88,114,100], [110,90,100]),
            kf_multi(45, [110,90,100], [100,100,100]),
            kf_multi(60, [100,100,100])
        ]),
        rot_anim=animated([
            kf(0, [0], [-12], 0.4,1,0.6,0),
            kf(15, [-12], [10], 0.4,1,0.6,0),
            kf(30, [10], [-8], 0.4,1,0.6,0),
            kf(45, [-8], [0], 0.4,1,0.6,0),
            kf(60, [0])
        ])
    )

    eyes = [
        make_layer("left_eye", [76, 92], [wink_eye_shape(22, 10, 3.5)], op),
        make_layer("right_eye", [124, 92], [wink_eye_shape(22, 10, 3.5)], op),
    ]

    ear_rot_l = animated([
        kf(0, [-15], [-40]), kf(15, [-40], [5], 0.5,1,0.5,0),
        kf(30, [5], [-35]), kf(45, [-35], [-15], 0.4,1,0.6,0), kf(60, [-15])
    ])
    ear_rot_r = animated([
        kf(0, [15], [40]), kf(15, [40], [-5], 0.5,1,0.5,0),
        kf(30, [-5], [35]), kf(45, [35], [15], 0.4,1,0.6,0), kf(60, [15])
    ])

    pig = base_pig_layers(op, eye_layers_override=eyes,
                          ear_rot_l=ear_rot_l, ear_rot_r=ear_rot_r)

    def star_shape(size, color=STAR_GOLD):
        s = size
        hs = size * 0.28
        verts = [[0, -s], [hs, -hs], [s, 0], [hs, hs], [0, s], [-hs, hs], [-s, 0], [-hs, -hs]]
        z = [0, 0]
        return path_shape(verts, [z]*8, [z]*8, True, color)

    # Many stars + colored confetti dots, two waves
    sparkle_specs = [
        # (cx, cy, size, delay, color, kind)
        (28, 40, 9, 0, STAR_GOLD, "star"),
        (172, 38, 10, 4, STAR_GOLD, "star"),
        (45, 160, 8, 10, STAR_GOLD, "star"),
        (158, 158, 9, 6, STAR_GOLD, "star"),
        (100, 18, 11, 12, STAR_GOLD, "star"),
        (20, 100, 7, 16, [1, 0.55, 0.30, 1], "dot"),
        (180, 100, 7, 18, [0.45, 0.85, 0.55, 1], "dot"),
        (60, 30, 6, 22, [0.55, 0.70, 1, 1], "dot"),
        (140, 30, 6, 24, [1, 0.55, 0.75, 1], "dot"),
        (100, 175, 8, 28, STAR_GOLD, "star"),
        (50, 70, 6, 32, [1, 0.55, 0.30, 1], "dot"),
        (155, 70, 6, 34, [0.45, 0.85, 0.55, 1], "dot"),
    ]
    for idx, (cx, cy, sz, delay, color, kind) in enumerate(sparkle_specs):
        if kind == "star":
            shape = star_shape(sz, color)
        else:
            shape = ellipse_shape(sz, sz, color)
        sparkle = make_layer(f"sparkle_{idx}", [cx, cy],
            [shape], op,
            scale=animated([
                kf_multi(delay, [0,0,100], [150,150,100]),
                kf_multi(min(delay+6, op), [150,150,100], [90,90,100]),
                kf_multi(min(delay+14, op), [90,90,100], [120,120,100]),
                kf_multi(min(delay+22, op), [120,120,100], [0,0,100]),
                kf_multi(min(delay+26, op), [0,0,100])
            ]),
            rotation=animated([
                kf(delay, [0], [60]),
                kf(min(delay+22, op), [60])
            ]))
        pig.append(sparkle)

    for i, layer in enumerate(pig):
        layer["ind"] = i + 1
        layer["parent"] = 0

    return wrap("celebrating", 30, op, [null] + pig)

# ===== pet_error =====
def gen_error():
    op = 45
    null = make_null("shake", 0, op,
        pos_anim=animated([
            kf(0, [100,100,0], [94,100,0], 0.5,1,0.5,0),
            kf(5, [94,100,0], [106,100,0], 0.5,1,0.5,0),
            kf(10, [106,100,0], [96,100,0], 0.5,1,0.5,0),
            kf(15, [96,100,0], [104,100,0], 0.5,1,0.5,0),
            kf(20, [104,100,0], [98,100,0], 0.5,1,0.5,0),
            kf(25, [98,100,0], [100,100,0], 0.4,1,0.6,0),
            kf(45, [100,100,0])
        ])
    )

    x_line1 = path_shape([[-5,-5],[5,5]], [[0,0],[0,0]], [[0,0],[0,0]], False, EYE_BLACK, stroke=True, stroke_w=2.8)
    x_line2 = path_shape([[5,-5],[-5,5]], [[0,0],[0,0]], [[0,0],[0,0]], False, EYE_BLACK, stroke=True, stroke_w=2.8)
    eyes = [
        make_layer("left_eye", [76, 92], [x_line1, x_line2], op),
        make_layer("right_eye", [124, 92], [x_line1, x_line2], op),
    ]

    pig = base_pig_layers(op, eye_layers_override=eyes)

    drop = path_shape(
        [[0, -7], [4, 2], [0, 7], [-4, 2]],
        [[0,0],[-2,-3],[0,0],[2,-3]], [[2,-3],[0,0],[-2,3],[0,0]],
        True, SWEAT_BLUE
    )
    sweat = make_layer("sweat", [148, 62], [drop], op,
        position_anim=animated([
            kf(0, [150,60,0], [150,72,0], 0.4,1,0.6,0),
            kf(15, [150,72,0], [150,60,0], 0.4,1,0.6,0),
            kf(30, [150,60,0], [150,72,0], 0.4,1,0.6,0),
            kf(45, [150,72,0])
        ]),
        scale=animated([
            kf_multi(0, [80,80,100], [100,100,100]),
            kf_multi(15, [100,100,100], [80,80,100]),
            kf_multi(30, [80,80,100], [100,100,100]),
            kf_multi(45, [100,100,100])
        ]))
    pig.append(sweat)

    for i, layer in enumerate(pig):
        layer["ind"] = i + 1
        layer["parent"] = 0

    return wrap("error", 30, op, [null] + pig)

# ===== pet_knocking =====
def gen_knocking():
    op = 30
    null = make_null("knock_bounce", 0, op,
        pos_anim=animated([
            kf(0, [100,100,0], [100,90,0], 0.5,1,0.5,0),
            kf(4, [100,90,0], [100,108,0], 0.5,1,0.5,0),
            kf(8, [100,108,0], [100,88,0], 0.5,1,0.5,0),
            kf(12, [100,88,0], [100,106,0], 0.5,1,0.5,0),
            kf(16, [100,106,0], [100,90,0], 0.5,1,0.5,0),
            kf(20, [100,90,0], [100,107,0], 0.5,1,0.5,0),
            kf(24, [100,107,0], [100,92,0], 0.5,1,0.5,0),
            kf(28, [100,92,0], [100,100,0], 0.4,1,0.6,0),
            kf(30, [100,100,0])
        ]),
        scale_anim=animated([
            kf_multi(0, [100,100,100], [104,96,100]),
            kf_multi(4, [104,96,100], [96,104,100]),
            kf_multi(8, [96,104,100], [104,96,100]),
            kf_multi(12, [104,96,100], [96,104,100]),
            kf_multi(16, [96,104,100], [103,97,100]),
            kf_multi(20, [103,97,100], [97,103,100]),
            kf_multi(24, [97,103,100], [100,100,100]),
            kf_multi(30, [100,100,100])
        ])
    )

    eyes = [
        open_eye_layer("left_eye", 76, 90, 17, 21, op),
        open_eye_layer("right_eye", 124, 90, 17, 21, op),
    ]

    ear_rot_l = animated([
        kf(0, [-15], [-32]), kf(4, [-32], [-2], 0.5,1,0.5,0),
        kf(8, [-2], [-30]), kf(12, [-30], [-4], 0.5,1,0.5,0),
        kf(16, [-4], [-28]), kf(20, [-28], [-6], 0.5,1,0.5,0),
        kf(24, [-6], [-20]), kf(28, [-20], [-15], 0.4,1,0.6,0),
        kf(30, [-15])
    ])
    ear_rot_r = animated([
        kf(0, [15], [32]), kf(4, [32], [2], 0.5,1,0.5,0),
        kf(8, [2], [30]), kf(12, [30], [4], 0.5,1,0.5,0),
        kf(16, [4], [28]), kf(20, [28], [6], 0.5,1,0.5,0),
        kf(24, [6], [20]), kf(28, [20], [15], 0.4,1,0.6,0),
        kf(30, [15])
    ])

    pig = base_pig_layers(op, eye_layers_override=eyes,
                          ear_rot_l=ear_rot_l, ear_rot_r=ear_rot_r)

    excl_body = rect_shape(6, 18, 3, EXCLAIM_RED)
    excl_dot = ellipse_shape(6, 6, EXCLAIM_RED)
    flash_scale = animated([
        kf_multi(0, [100,100,100], [120,120,100]),
        kf_multi(5, [120,120,100], [0,0,100]),
        kf_multi(10, [0,0,100], [110,110,100]),
        kf_multi(15, [110,110,100], [0,0,100]),
        kf_multi(20, [0,0,100], [105,105,100]),
        kf_multi(25, [105,105,100], [0,0,100]),
        kf_multi(30, [0,0,100])
    ])
    pig.append(make_layer("excl_body", [100, 22], [excl_body], op, scale=flash_scale))
    pig.append(make_layer("excl_dot", [100, 38], [excl_dot], op, scale=flash_scale))

    for i, layer in enumerate(pig):
        layer["ind"] = i + 1
        layer["parent"] = 0

    return wrap("knocking", 30, op, [null] + pig)

# ===== Generate all =====
animations = {
    "pet_awake": gen_awake(),
    "pet_sleeping": gen_sleeping(),
    "pet_thinking": gen_thinking(),
    "pet_working": gen_working(),
    "pet_celebrating": gen_celebrating(),
    "pet_error": gen_error(),
    "pet_knocking": gen_knocking(),
}

os.makedirs(RESOURCES, exist_ok=True)
for name, data in animations.items():
    path = os.path.join(RESOURCES, f"{name}.json")
    with open(path, "w") as f:
        json.dump(data, f, indent=2)
    print(f"wrote {path}")

print("done!")

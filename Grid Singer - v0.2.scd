(
s.waitForBoot({

    //============================
    // WINDOW & BASE SETUP
    //============================

    var h = 720, w = 1080;                         // Window dimensions
    var win = Window("GridSinger", Rect(100, 100, w, h));

    //============================
    // VARIABLE DECLARATIONS
    //============================

    var canvas;                                    // Drawing surface
    var spawnOne;                                  // Function for spawning obstacles

    // --- Character Variables ---
    var r = 8;                                     // Character radius
    var d = r * 2;                                 // Character diameter
    var rHit = r - 0.01;                           // Collision radius
    var charPos = Point(120, h - 50);              // Starting position
    var velocity = 0.0;                            // Vertical velocity
    var gravity = -1.5;                            // Gravity applied each frame

    // --- Microphone Amplitude ---
    var amp = 0.0;                                 // Incoming amplitude value
    var ampSynth;                                  // Synth tracking amplitude

    // --- Game State ---
    var alive = true;                              // Player alive flag
    var obstacles = List.new;                      // Active obstacle list
    var spawnCooldown = 0.0;                       // Time until next obstacle
    var spawnMin = 0.65, spawnMax = 1.25;          // Spawn interval range
    var speed = 9.0;                               // Base obstacle speed

    // --- Roof & Breaker Objects ---
    var roofH = 20;                                // Roof height
    var breakAmpThresh = 0.12;                     // Smash threshold
    var breakerProb = 0.15;                        // Chance of spawning breaker

    // --- Halo & Trail Visuals ---
    var safeGrace = 0.45;                          // Smash time window
    var safeTimer = 0.0;                           // Time remaining in smash window
    var t = 0.0;
    var trail = List.new;                          // Visual trail behind character
    var trailLife = 0.45;                          // Trail lifetime
    var burstProb = 0.35;                          // Chance of double spawn

    // --- Scoring ---
    var score = 0;                                 // Score counter
    var timeAccum = 0.0;                           // Timing for score increase

    // --- Mana ---
    var mana = 0;                                  // Mana amount 0–100
    var manaTick = 0.0;                            // Looping tick timer = 0.15s
    var manaBtn;                                   // Invincibility button

	// --- Cloak Skill ---
    var invincible = false;                        // Invincibility active?
    var invincibleTime = 2.0;                      // Cloak Duration
    var invincibleTimer = 0.0;                     // Cloak Sustain

    // --- Blink Skill ---
    var blinkBtn;                                  // Blink button
    var blinkSafeTimer = 0.0;                      // Post-blink immunity (0.08 sec)

    // --- Replay Button ---
    var replayBtn;

    // --- Helper Functions ---
    var clamp;                                     // Utility clamp
    var circleIntersectsRect;                      // Collision helper

    clamp = { |x, lo, hi| x.max(lo).min(hi) };     // Clamp character's Y in screen

    // --- Collision detection ---
    circleIntersectsRect = { |cx, cy, rr, rx, ry, rw, rh|
        var nearestX = clamp.(cx, rx, rx + rw);
        var nearestY = clamp.(cy, ry, ry + rh);
        var dx = cx - nearestX;
        var dy = cy - nearestY;
        ((dx * dx + dy * dy) <= (rr * rr)) // 1 if character center to closest obstacle squared < radius squared
    };

    //============================
    // DRAWING VIEW
    //============================

    canvas = UserView(win, win.view.bounds)
        .background_(Color(0.06, 0.06, 0.08))
        .drawFunc_({
            var shadowY;     // Blink shadow vertical reflection

            // --- Score text ---
            ("Score: " ++ score).drawAtPoint(Point(20, 24),
                Font("Helvetica-Bold", 22), Color(1, 0.9, 0.2));

            // --- Mana text display ---
            ("Mana: " ++ mana).drawAtPoint(Point(20, 50),
                Font("Helvetica-Bold", 20), Color(0.6, 0.8, 1.0));

            // --- Roof ---
            Pen.fillColor = Color.blue;
            Pen.fillRect(Rect(0, 0, w, roofH));

            // --- Obstacles ---
            obstacles.do { |o|
                Pen.fillColor = (o[\type] == \breaker).if({ Color.cyan }, { Color.blue });
                Pen.fillRect(Rect(o[\x], o[\y], o[\w], o[\h]));
            };

            // --- Visual Trail ---
            trail.do { |p|
                var a = (p[\life] / trailLife).clip(0, 1);
                var size = d * (1 + 2.5 * (1 - a));
                Pen.fillColor = Color(1, 0.85, 0.2, 0.10 * a);
                Pen.addOval(Rect.aboutPoint(Point(p[\x], p[\y]), size * 1.6, size * 1.6)); Pen.fill;
                Pen.fillColor = Color(1, 0.65, 0, 0.18 * a);
                Pen.addOval(Rect.aboutPoint(Point(p[\x], p[\y]), size, size)); Pen.fill;
            };

            // --- Character + Halo ---
            Pen.push;

            if ((amp >= breakAmpThresh) or: { safeTimer > 0 } or: { invincible }) {
                var pulse = (sin(t * 6) * 0.12 + 0.88);
                var halo1 = d * (3.0 * pulse);
                var halo2 = d * (2.0 * pulse);

                Pen.fillColor = invincible.if(
                    { Color(0.4, 1, 1, 0.25) }, { Color(1, 0.9, 0.25, 0.18) });
                Pen.addOval(Rect.aboutPoint(Point(charPos.x, charPos.y), halo1, halo1)); Pen.fill;

                Pen.fillColor = invincible.if(
                    { Color(0.2, 0.9, 1, 0.30) }, { Color(1, 0.75, 0.1, 0.28) });
                Pen.addOval(Rect.aboutPoint(Point(charPos.x, charPos.y), halo2, halo2)); Pen.fill;
            };

            // --- Character color depending on state ---
            Pen.fillColor = invincible.if(
                { Color(0.3, 1, 1) },
                {
                    ((amp >= breakAmpThresh) or: { safeTimer > 0 })
                        .if({ Color(1, 0.82, 0) },
                            { alive.if({ Color(0.85, 0.2, 0.2) }, { Color.gray(0.7) }) })
                }
            );

            Pen.translate(charPos.x, charPos.y);
            Pen.addOval(Rect.aboutPoint(Point(0, 0), d, d)); Pen.fill;
            Pen.pop;

            // --- Blink Shadow ---
            if (alive) {
                shadowY = h - charPos.y;
                Pen.fillColor = Color(0.5, 0.8, 1.0, 0.18);
                Pen.addOval(Rect.aboutPoint(Point(charPos.x, shadowY), d, d)); Pen.fill;
                Pen.fillColor = Color(0.5, 0.8, 1.0, 0.10);
                Pen.addOval(Rect.aboutPoint(Point(charPos.x, shadowY), d * 2, d * 2)); Pen.fill;
            };

            // --- Gameover Page ---
            if (alive.not) {
                Pen.fillColor = Color(0, 0, 0, 0.55);
                Pen.fillRect(Rect(0, 0, w, h));
                replayBtn.visible = true;
                manaBtn.visible = false;
                blinkBtn.visible = false;

                "GAME OVER".drawAtPoint(Point(w * 0.5 - 160, h * 0.25),
                    Font("Helvetica-Bold", 48), Color(1, 0.85, 0.2));

                ("Final Score: " ++ score).drawAtPoint(Point(w * 0.5 - 120, h * 0.25 + 52),
                    Font("Helvetica-Bold", 28), Color(1, 0.9, 0.2));
            };
        });

    win.front;

    //============================
    // BUTTONS
    //============================

    // --- Replay button ---
    replayBtn = Button(win, Rect(w * 0.5 - 105, h * 0.25 + 135, 140, 40))
        .states_([["Replay", Color.white, Color(0.2, 0.6, 0.2)]])
        .action_({
            alive = true;
            score = 0;
            timeAccum = 0.0;
            charPos = Point(120, h - 50);
            velocity = 0.0;

            obstacles = List.new;
            trail = List.new;

            safeTimer = 0.0;
            t = 0.0;

            mana = 0;
            manaTick = 0.0;

            invincible = false;
            invincibleTimer = 0.0;

            blinkSafeTimer = 0.0;

            spawnCooldown = 0.0;

            replayBtn.visible = false;
            manaBtn.visible = true;
            blinkBtn.visible = true;
        })
        .visible_(false);

    // --- Invincibility button ---
    manaBtn = Button(win, Rect(w * 0.5 - 90, h - 60, 180, 30))
        .states_([["Invincible (100)", Color.white, Color(0.3, 0.3, 0.3)]])
        .action_({
            if (alive and: { mana >= 100 }) {
                mana = 0;
                invincible = true;
                invincibleTimer = invincibleTime;
            };
        })
        .visible_(true);

    // --- Blink button ---
    blinkBtn = Button(win, Rect(w * 0.5 - 90, h - 100, 180, 30))
        .states_([["Blink (40)", Color.white, Color(0.3, 0.3, 0.3)]])
        .action_({
            if (alive and: { mana >= 40 }) {
                mana = mana - 40;
                charPos = Point(charPos.x, h - charPos.y);   // Reflect over midline
                blinkSafeTimer = 0.08;                       // Immunity
            };
        })
        .visible_(true);

    //============================
    // SKILL KEYBOARD MAPPING
    //============================

    win.view.keyDownAction = { |view, char|
        var key = char.asString;

        if (alive) {

			// --- Blink (Z) ---
            if (key == "z" or: { key == "Z" }) {
                if (mana >= 40) {
                    mana = mana - 40;
                    charPos = Point(charPos.x, h - charPos.y);
                    blinkSafeTimer = 0.08;
                };
            };

			// --- Invincible (X) ---
            if (key == "x" or: { key == "X" }) {
                if (mana >= 100) {
                    mana = 0;
                    invincible = true;
                    invincibleTimer = invincibleTime;
                };
            };
        };
    };

    //============================
    // AMP TRACKING SYNTH
    //============================

    SynthDef(\trackAmp, {
        var mic = SoundIn.ar(0);                 // Read microphone
        var a = Amplitude.kr(mic, 0.05, 0.05);   // Smoothing
        SendReply.kr(Impulse.kr(30), "/amp", a); // Send value 30 fps
        Silent.ar;
    }).add;

    s.sync;
    ampSynth = Synth(\trackAmp);

    OSCdef(\ampListener, { |msg| amp = msg[3] ? 0.0; }, "/amp");

    //============================
    // SPAWNER
    //============================

    spawnOne = {
        var sx = w + 20;

        if (1.0.rand < breakerProb) {
            obstacles.add((\type: \breaker, \x: sx, \y: 0, \w: 10, \h: h,
                \speed: speed + rrand(-1.0, 1.0)));
        } {
            var bw = rrand(60, 120);
            var bh = rrand(120, 360);
            var yMin = r + roofH;
            var yMax = (h - bh - r).max(yMin);
            var by;
            var mode = 1.0.rand;                // Distribute spawn location

			if (mode < 0.50) {                  // 50% Bottom
                bh = (bh * 1.1).clip(80, h - (2 * r) - roofH);
                yMax = (h - bh - r).max(yMin);
                by = yMax;
            } {
                if (mode < 0.70) {              // 20% Lower mid
                    by = yMin + (yMax - yMin) * (1.0.rand.pow(0.5));
                } {
                    if (mode < 0.90) {          // 20% Mid
                        var midY = ((h - bh) * 0.5).clip(yMin, yMax);
                        by = (midY + rrand(-40, 40)).clip(yMin, yMax);
                    } {
                        bh = rrand(40, 160);    // 10% Roof
                        by = yMin;
                    };
                };
            };

            obstacles.add((\type: \normal, \x: sx, \y: by, \w: bw, \h: bh,
                \speed: speed + rrand(-2.0, 2.5)));
        };
    };

    //============================
    // GAME LOOP
    //============================

    Routine({
        var dt = 1 / 30;
        var maxY = { canvas.bounds.height - d };
        var frameWait = 0.033;
        var randSpawn = { rrand(spawnMin, spawnMax) };
		var floorY = maxY.() + r;
        spawnCooldown = randSpawn.();

        loop {
            if (alive) {

                t = t + dt;

                // --- Score Update ---
                timeAccum = timeAccum + dt;
                if (timeAccum >= 0.1) {
                    score = score + 1;
                    timeAccum = timeAccum - 0.1;
                };

                // --- Mana Update ---
                manaTick = manaTick + dt;
                if (manaTick >= 0.15) {
                    manaTick = manaTick - 0.15;
                    if (mana < 100) { mana = mana + 1 };
                };

                // --- Button Colors Update ---
                manaBtn.states_([
                    (mana >= 100)
                        .if({ ["Cloak (100) - Press X", Color.white, Color(0.1, 0.5, 1.0)] },
                            { ["Cloak (100) - Press X", Color.white, Color(0.3, 0.3, 0.3)] })
                ]);

                blinkBtn.states_([
                    (mana >= 40)
                        .if({ ["Blink (40) - Press Z", Color.white, Color(0.6, 0.6, 1.0)] },
                            { ["Blink (40) - Press Z", Color.white, Color(0.3, 0.3, 0.3)] })
                ]);

                // --- Cloak Timer ---
                if (invincible) {
                    invincibleTimer = invincibleTimer - dt;
                    if (invincibleTimer <= 0) { invincible = false };
                };

                // --- Blink Grace ---
                if (blinkSafeTimer > 0) { blinkSafeTimer = blinkSafeTimer - dt };

                // --- Microphone Thrust ---
                if (amp > 0.03) { velocity = amp.linexp(0.03, 0.5, 5, 50) };

                // --- Barrier Smash ---
                if (amp >= breakAmpThresh) { safeTimer = safeGrace } {
                    safeTimer = (safeTimer - dt).max(0);
                };

				// --- Gravity + Roof Detection ---

				velocity = velocity + gravity;
				charPos.y = charPos.y - velocity;

				// --- Roof collision ---
				if (alive and: invincible.not and: { blinkSafeTimer <= 0 }) {
					// Roof rectangle is (0, 0, w, roofH)
					if (circleIntersectsRect.(charPos.x, charPos.y, rHit, 0, 0, w, roofH)) {
						alive = false;
					};
				};

				// --- Clamp bottom only ---

				if (charPos.y > floorY) {
					charPos.y = floorY;
				};


                // --- Character Trail ---
                if ((amp >= breakAmpThresh) or: { safeTimer > 0 } or: { invincible }) {
                    trail.add((\x: charPos.x, \y: charPos.y, \life: trailLife));
                    if (trail.size > 200) { trail.removeAt(0) };
                };
                trail.do { |p| p[\life] = p[\life] - dt };
                trail = trail.reject { |p| p[\life] <= 0 }.as(List);

                // --- Obstacle Movement ---
                obstacles.do { |o| o[\x] = o[\x] - o[\speed] };
                obstacles = obstacles.reject { |o| (o[\x] + o[\w]) < 0 }.as(List);

                // --- Spawning Logic ---
                spawnCooldown = spawnCooldown - dt;
                if (spawnCooldown <= 0) {
                    spawnOne.();
                    if (1.0.rand < burstProb) { spawnOne.() };
                    spawnCooldown = randSpawn.();
                };

                // --- Roof Collision ---
                if (invincible.not and: { blinkSafeTimer <= 0 }) {
                    if (circleIntersectsRect.(charPos.x, charPos.y, rHit, 0, 0, w, roofH)) {
                        alive = false;
                    };
                };

                // --- Obstacle Collision ---
                if (alive) {
                    var toRemove = List.new;

					// Only activate the collision logic when the obstacle is on the character's horizontal coordinate
                    obstacles.do { |o|
                        var left = o[\x], right = left + o[\w];
                        var nearHoriz = (right >= (charPos.x - rHit)) && (left <= (charPos.x + rHit));

                        if (nearHoriz) {
                            if (circleIntersectsRect.(charPos.x, charPos.y, rHit,
                                o[\x], o[\y], o[\w], o[\h])) {

                                if (invincible or: { blinkSafeTimer > 0 }) {
									// Ignore damage (This bracket is deliberately left empty)
                                } {
                                    if (o[\type] == \breaker) {
                                        if ((amp >= breakAmpThresh) or: { safeTimer > 0 }) {
                                            toRemove.add(o); score = score + 50;
                                        } {
                                            alive = false;
                                        };
                                    } {
                                        alive = false;
                                    };
                                };
                            };
                        };
                    };

					// --- Obstacle Removal ---
                    if (toRemove.notEmpty) {
                        obstacles = obstacles.reject { |o| toRemove.includes(o) }.as(List);
                    };
                };
            };

            { canvas.refresh }.defer;
            frameWait.wait;
        };
    }).play(AppClock);

    //============================
    // CLEANUP ON CLOSE
    //============================

    win.onClose_({
        try { ampSynth.free } { };
        try { OSCdef(\ampListener).free } { };
    });

});
)

shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform float progress : hint_range(0.0, 1.0) = 1.0;
uniform float thickness : hint_range(0.01, 0.2) = 0.08;
uniform vec4 color : source_color = vec4(1.0, 0.0, 0.0, 1.0);

void fragment() {
    vec2 center = vec2(0.5);
    vec2 delta = UV - center;
    float dist = length(delta);

    // Кольцо с прозрачностью
    float ring_in = smoothstep(0.45, 0.5 - thickness, dist);
    float ring_out = 1.0 - smoothstep(0.5 - thickness, 0.5, dist);
    float ring = ring_in * ring_out;

    float angle = atan(delta.y, delta.x) / (6.28318) + 0.25;
    angle = fract(angle);

    // ✅ ИСПРАВЛЕНО: против часовой (было angle < progress)
    float sector = (angle > (1.0 - progress)) ? 1.0 : 0.0;

    float alpha = ring * sector * color.a;
    COLOR = vec4(color.rgb, alpha);
}

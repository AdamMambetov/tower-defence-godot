shader_type canvas_item;

uniform bool active = false;
uniform vec4 glow_color : source_color = vec4(1.0, 0.4, 0.1, 1.0);
uniform float glow_intensity : hint_range(0.0, 3.0) = 1.5;
uniform float glow_radius : hint_range(0.0, 1.0) = 0.4;
uniform float pulse_speed : hint_range(0.0, 5.0) = 2.0;
uniform float pulse_strength : hint_range(0.0, 1.0) = 0.3;

void fragment() {
    vec4 color = texture(TEXTURE, UV);

    if (active) {
        // Узнаём размер текстуры в пикселях
        vec2 tex_size = 1.0 / TEXTURE_PIXEL_SIZE;
        float aspect = tex_size.x / tex_size.y;

        // Приводим UV к центру и компенсируем соотношение сторон
        vec2 centered = UV - 0.5;
        centered.x *= aspect;

        // Расстояние от центра с учётом пропорций
        float dist = length(centered);

        // Максимальное расстояние до угла (с учётом aspect)
        float max_dist = length(vec2(0.5 * aspect, 0.5));

        // Нормализуем расстояние в диапазон [0, 1]
        float normalized_dist = dist / max_dist;

        // Пульсирующий радиус (не даём ему выходить за 1.0)
        float time = TIME * pulse_speed;
        float pulse = sin(time) * pulse_strength;
        float current_radius = clamp(glow_radius + pulse, 0.0, 1.0);

        // Плавное затухание от центра к краю
        float glow_factor = 1.0 - smoothstep(0.0, current_radius, normalized_dist);
        glow_factor = pow(glow_factor, 1.5); // делаем край мягче
        glow_factor *= glow_intensity;

        // Мерцание цвета (опционально)
        vec3 pulsed_color = glow_color.rgb * (0.8 + 0.4 * sin(time * 2.0));

        COLOR = color + vec4(pulsed_color, 1.0) * glow_factor;
    } else {
        COLOR = color;
    }
}
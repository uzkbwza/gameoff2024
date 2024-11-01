uniform vec2 viewport_size;
uniform vec2 canvas_size;
uniform vec2 canvas_pos;

uniform float rgb_amount = 0.15;
uniform float rgb_brightness = 4.55;
uniform float border_size = 150.0;
uniform float border_feather = 0.5;
uniform float border_amount = 0.8; // 0.5
uniform float aberration_amount = 0.1;
uniform float aberration_strength = 0.6;
uniform float aberration_blur_size = 0.45;   // Controls the aberration blur size
uniform int aberration_blur_samples = 7;     // Controls the number of samples in the aberration blur

// New uniforms for the pre-aberration blur
uniform float pre_blur_size = 0.05;           // Controls the pre-aberration blur size
uniform int pre_blur_samples = 4;            // Controls the number of samples in the pre-aberration blur

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec2 uv = (screen_coords - floor(canvas_pos)) / canvas_size;
    vec2 pixel_coords = uv * viewport_size;
    vec2 pixel_uv = mod(pixel_coords, 1.0);
    vec2 pixel_size = 1.0 / viewport_size;
    vec2 screen_pixel_size = 1.0 / canvas_size;
    float pixel_scale = screen_pixel_size.x / pixel_size.x;

    float dist = (1.0 - pixel_uv.x);
    float bsize = (pixel_scale * 0.002) * border_size;
    dist = min(pixel_uv.y, dist);

    float dist2 = 1.0 - pixel_uv.x;
    dist2 = min(1.0 - pixel_uv.y, dist2);
    float border = 0.5 + smoothstep(bsize - border_feather, bsize + border_feather, dist) * 0.5;
    float border2 = smoothstep(bsize - border_feather, bsize + border_feather, dist2) * 0.5;

    float aberration = max(aberration_amount * (1.0 + pixel_scale * 0.0005), sign(aberration_amount) * pixel_scale);
    float aberration_offset = aberration * pixel_size.x;

    // Pre-aberration blur
    vec4 blurred_color = vec4(0.0);
    float pre_total_weight = 0.0;

    int pre_half_samples = pre_blur_samples / 2;
    for (int i = -pre_half_samples; i <= pre_half_samples; i++) {
        for (int j = -pre_half_samples; j <= pre_half_samples; j++) {
            vec2 offset = vec2(float(i), float(j)) * pre_blur_size * pixel_size;
            float weight = exp(-0.5 * (float(i * i + j * j) / float(pre_half_samples * pre_half_samples)));
            blurred_color += Texel(texture, uv + offset) * weight;
            pre_total_weight += weight;
        }
    }
    blurred_color /= pre_total_weight;

    // Now apply chromatic aberration to the blurred color
    float r = 0.0;
    float g = blurred_color.g;
    float b = 0.0;
    float a = blurred_color.a;

    float aberration_total_weight = 0.0;
    int aberration_half_samples = aberration_blur_samples / 2;

    for (int i = -aberration_half_samples; i <= aberration_half_samples; i++) {
        float sample_offset = float(i) * (aberration_blur_size / float(aberration_half_samples)) * pixel_size.x;
        float weight = exp(-0.5 * pow(float(i) / float(aberration_half_samples), 2.0));

        aberration_total_weight += weight;

        // Apply aberration to the blurred color
        r += Texel(texture, uv + vec2(aberration_offset + sample_offset, 0.0)).r * weight;
        b += Texel(texture, uv - vec2(aberration_offset + sample_offset, 0.0)).b * weight;
    }

    r /= aberration_total_weight;
    b /= aberration_total_weight;

    // Mix the blurred and aberrated colors
    r = mix(r, blurred_color.r, 1.0 - aberration_strength);
    b = mix(b, blurred_color.b, 1.0 - aberration_strength);

    vec4 pixel = vec4(r, g, b, a) * mix(1.0, border, border_amount) * mix(1.0, 0.75 + border2, border_amount);

    return pixel;
}

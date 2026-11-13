#language slang 2026

import kitty_custom_shader_types;
static const float max_dimming = 0.08;

public float4 fragment_main(float4 color, KittyTextures t,
                            KittyCustomShaderData d) {
    float4 rect = d.bell_window_geometry;
    float2 rect_end = rect.xy + rect.zw;
    if (rect.z <= 0.0 || rect.w <= 0.0 || any(t.pos < rect.xy) ||
        any(t.pos >= rect_end)) {
        return color;
    }

    float pulse = sin(3.14159265 * t.animation_progress);
    float brightness = 1.0 - max_dimming * pulse * pulse;
    return float4(color.rgb * brightness, color.a);
}

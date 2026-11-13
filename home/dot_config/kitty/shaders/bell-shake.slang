#language slang 2026

import kitty_custom_shader_types;
static const float max_displacement = 17.5;

public float4 fragment_main(float4 color, KittyTextures t,
                            KittyCustomShaderData d) {
    float4 rect = d.bell_window_geometry;
    float2 rect_end = rect.xy + rect.zw;
    if (rect.z <= 0.0 || rect.w <= 0.0 || any(t.pos < rect.xy) ||
        any(t.pos >= rect_end)) {
        return color;
    }

    float direction = (d.frame_counter & 1u) == 0u ? 1.0 : -1.0;
    float pixels = direction * max_displacement * (1.0 - t.animation_progress);
    float2 sample_pos = t.pos;
    sample_pos.x -= pixels / float(d.viewport_size_pixels.x);

    float4 sampled = t.backbuffer.Sample(sample_pos);
    return float4(sampled.rgb / max(sampled.a, 1e-6), sampled.a);
}

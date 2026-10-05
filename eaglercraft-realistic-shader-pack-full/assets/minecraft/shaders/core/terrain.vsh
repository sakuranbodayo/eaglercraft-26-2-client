#version 330

// Realistic Terrain (vertex)  -  Eaglercraft 26.x core shader override
// ・草/シダ/サトウキビ: 先端だけが風で揺れる(根元は固定)
// ・水面: 縦方向のみのサイン波(隙間・割れが出ない)

#moj_import <minecraft:fog.glsl>
#moj_import <minecraft:globals.glsl>
#moj_import <minecraft:chunksection.glsl>
#moj_import <minecraft:projection.glsl>
#moj_import <minecraft:sample_lightmap.glsl>

#define TAU 6.28318530718
#define WIND_STRENGTH 1.8   // 風の強さ (0.0 で無効)
#define LEAF_STRENGTH 1.0   // 葉の揺れの強さ (0.0 で無効)
#define WAVE_HEIGHT 1.0     // 波の高さ (0.0 で無効)
// 草が根元から揺れて見える場合は 0/3 を 1/2 に入れ替える
#define TIP_A 0
#define TIP_B 3

in vec3 Position;
in vec4 Color;
in vec2 UV0;
in ivec2 UV2;

uniform sampler2D Sampler2;

out float sphericalVertexDistance;
out float cylindricalVertexDistance;
out vec4 vertexColor;
out vec2 texCoord0;
out vec3 viewPosV;
out vec3 worldPosV;
out float skyLightV;
out float waterV;

// 周期が整数なので GameTime が 1 -> 0 に戻っても波が飛ばない
float tw(float cycles) {
    return TAU * cycles * GameTime;
}

bool isFrac(float v) {
    return abs(v - floor(v + 0.5)) > 0.004;
}

vec3 windSway(vec3 wp) {
    vec2 dir = vec2(0.8, 0.6);
    vec2 perp = vec2(-0.6, 0.8);
    float w = dot(wp.xz, dir);
    float gust = 0.65 + 0.35 * sin(w * 0.12 - tw(150.0)) * sin(dot(wp.xz, perp) * 0.08 - tw(90.0));
    float s1 = sin(w * 0.8 - tw(480.0));
    float s2 = 0.5 * sin(dot(wp.xz, perp) * 1.5 - tw(840.0));
    float sway = (s1 + s2) * gust;
    float side = sin(w * 0.55 - tw(300.0)) * 0.3 * gust;
    return vec3(dir.x * sway + perp.x * side, 0.0, dir.y * sway + perp.y * side);
}

// 葉: ワールド座標だけで決まる連続な揺れ(隣の葉と必ず同じ動きになり割れない)
vec3 leafSway(vec3 wp) {
    vec2 dir = vec2(0.8, 0.6);
    vec2 perp = vec2(-0.6, 0.8);
    float w = dot(wp.xz, dir);
    float gust = 0.65 + 0.35 * sin(w * 0.12 - tw(150.0)) * sin(dot(wp.xz, perp) * 0.08 - tw(90.0));
    float a = sin(w * 0.9 - tw(600.0) + wp.y * 0.8);
    float b = 0.6 * sin(dot(wp.xz, perp) * 1.3 - tw(900.0) + wp.y * 1.1);
    float c = 0.5 * sin(wp.y * 1.7 + w * 0.5 - tw(1200.0));
    return vec3(dir.x * (a + b) + perp.x * c, 0.5 * c, dir.y * (a + b) + perp.y * c) * gust;
}

float waterHeight(vec2 p) {
    float h = 0.0;
    h += 0.022 * sin(dot(normalize(vec2(0.90, 0.44)), p) * (TAU / 13.0) - tw(120.0));
    h += 0.016 * sin(dot(normalize(vec2(-0.50, 0.87)), p) * (TAU / 9.0) - tw(160.0));
    h += 0.008 * sin(dot(normalize(vec2(0.20, -0.98)), p) * (TAU / 5.5) - tw(260.0));
    return h;
}

void main() {
    vec3 wp = Position + vec3(ChunkPosition);
    vec3 pos = Position + vec3(ChunkPosition - CameraBlockPos) + CameraOffset;

    bool fx = isFrac(wp.x);
    bool fy = isFrac(wp.y);
    bool fz = isFrac(wp.z);

    // 色付き(バイオーム色)で緑 = 草・シダ・葉 / 青 = 水
    bool green = Color.g > Color.r * 1.02 && Color.g > Color.b * 1.2;
    bool isWater = Color.b > Color.r * 1.5 && Color.b > Color.g * 1.05;
    // 斜め交差モデル: x,z が端数 / y が整数。スイレン(y が端数)は除外
    bool isPlant = green && fx && fz && !fy;

    float sky = float(UV2.y) / 240.0;
    float exposure = mix(0.4, 1.0, smoothstep(0.3, 0.9, sky));

    vec3 off = vec3(0.0);
    int corner = gl_VertexID & 3;
    bool tip = (corner == TIP_A) || (corner == TIP_B);
    if (isPlant && tip) {
        vec3 s = windSway(wp) * 0.16 * WIND_STRENGTH * exposure;
        s.y = -length(s.xz) * 0.45;   // 曲がっても長さを保つ
        off += s;
    }
    // 葉(緑の立方体頂点)。振幅を小さくして他ブロックとの境目に隙間を出さない
    if (green && !fx && !fz) {
        off += leafSway(wp) * 0.035 * LEAF_STRENGTH * exposure;
    }
    if (isWater && fy) {
        off.y += waterHeight(wp.xz) * WAVE_HEIGHT;
    }
    pos += off;

    vec4 viewPos4 = ModelViewMat * vec4(pos, 1.0);
    gl_Position = ProjMat * viewPos4;

    sphericalVertexDistance = fog_spherical_distance(pos);
    cylindricalVertexDistance = fog_cylindrical_distance(pos);
    vertexColor = Color * sample_lightmap(Sampler2, UV2);
    texCoord0 = UV0;

    viewPosV = viewPos4.xyz;
    worldPosV = wp;
    skyLightV = sky;
    waterV = isWater ? 1.0 : 0.0;
}

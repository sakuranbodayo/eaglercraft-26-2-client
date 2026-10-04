#version 330

#moj_import <minecraft:fog.glsl>
#moj_import <minecraft:globals.glsl>
#moj_import <minecraft:chunksection.glsl>

uniform sampler2D Sampler0;

in float sphericalVertexDistance;
in float cylindricalVertexDistance;
in vec4 vertexColor;
in vec2 texCoord0;
in vec3 viewPosV;
in vec3 worldPosV;
in float skyLightV;
in float waterV;


out vec4 fragColor;

vec4 sampleNearest(sampler2D source, vec2 uv, vec2 pixelSize, vec2 du, vec2 dv, vec2 texelScreenSize) {
    // Convert our UV back up to texel coordinates and find out how far over we are from the center of each pixel
    vec2 uvTexelCoords = uv / pixelSize;
    vec2 texelCenter = round(uvTexelCoords) - 0.5f;
    vec2 texelOffset = uvTexelCoords - texelCenter;

    // Move our offset closer to the texel center based on texel size on screen
    texelOffset = (texelOffset - 0.5f) * pixelSize / texelScreenSize + 0.5f;
    texelOffset = clamp(texelOffset, 0.0f, 1.0f);

    uv = (texelCenter + texelOffset) * pixelSize;
    return textureGrad(source, uv, du, dv);
}

vec4 sampleNearest(sampler2D source, vec2 uv, vec2 pixelSize) {
    vec2 du = dFdx(uv);
    vec2 dv = dFdy(uv);
    vec2 texelScreenSize = sqrt(du * du + dv * dv);
    return sampleNearest(source, uv, pixelSize, du, dv, texelScreenSize);
}

// Rotated Grid Super-Sampling
vec4 sampleRGSS(sampler2D source, vec2 uv, vec2 pixelSize) {
    vec2 du = dFdx(uv);
    vec2 dv = dFdy(uv);

    vec2 texelScreenSize = sqrt(du * du + dv * dv);
    float maxTexelSize = max(texelScreenSize.x, texelScreenSize.y);

    float minPixelSize = min(pixelSize.x, pixelSize.y);

    float transitionStart = minPixelSize * 1.0;
    float transitionEnd = minPixelSize * 2.0;
    float blendFactor = smoothstep(transitionStart, transitionEnd, maxTexelSize);

    float duLength = length(du);
    float dvLength = length(dv);
    float minDerivative = min(duLength, dvLength);
    float maxDerivative = max(duLength, dvLength);

    float effectiveDerivative = sqrt(minDerivative * maxDerivative);

    float mipLevelExact = max(0.0, log2(effectiveDerivative / minPixelSize));

    float mipLevelLow = floor(mipLevelExact);
    float mipLevelHigh = mipLevelLow + 1.0;
    float mipBlend = fract(mipLevelExact);

    const vec2 offsets[4] = vec2[](
    vec2(0.125, 0.375),
    vec2(-0.125, -0.375),
    vec2(0.375, -0.125),
    vec2(-0.375, 0.125)
    );

    vec4 rgssColorLow = vec4(0.0);
    vec4 rgssColorHigh = vec4(0.0);
    for (int i = 0; i < 4; ++i) {
        vec2 sampleUV = uv + offsets[i] * pixelSize;
        rgssColorLow += textureLod(source, sampleUV, mipLevelLow);
        rgssColorHigh += textureLod(source, sampleUV, mipLevelHigh);
    }
    rgssColorLow *= 0.25;
    rgssColorHigh *= 0.25;

    vec4 rgssColor = mix(rgssColorLow, rgssColorHigh, mipBlend);

    vec4 nearestColor = sampleNearest(source, uv, pixelSize, du, dv, texelScreenSize);

    return mix(nearestColor, rgssColor, blendFactor);
}


#define TAU 6.28318530718
#define SUN_SHADOW 1.0        // 日向/日陰のコントラスト (0.0 で無効)
#define WATER_REFLECTION 1.0  // 水面の空の反射 (0.0 で無効)
#define FOG_SCATTER 1.0       // 太陽方向の大気散乱 (0.0 で無効)
#define SATURATION 1.12       // 彩度
#define EXPOSURE 1.0          // 明るさ (0.8 - 1.3)

float luma(vec3 c) {
    return dot(c, vec3(0.2126, 0.7152, 0.0722));
}

// バニラの天体回転式から太陽の向き (+x = 東)
vec3 getSunDir() {
    float t = fract(GameTime - 0.25);
    float e = 0.5 - cos(t * 3.14159265) * 0.5;
    float a = (2.0 * t + e) / 3.0;
    return vec3(-sin(a * TAU), cos(a * TAU), 0.0);
}

vec3 sunTransmittance(float h) {
    float am = 1.0 / (max(h, 0.0) + 0.02);
    return exp(-vec3(0.0116, 0.0270, 0.0660) * am);
}

// フィルミックなトーンカーブ (J. Hable の公開式)。中間を明るく、影を深く
vec3 hableTonemap(vec3 x) {
    const float A = 0.15;
    const float B = 0.50;
    const float C = 0.10;
    const float D = 0.20;
    const float E = 0.02;
    const float F = 0.30;
    return ((x * (A * x + C * B) + D * E) / (x * (A * x + B) + D * F)) - E / F;
}

float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float vnoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash21(i);
    float b = hash21(i + vec2(1.0, 0.0));
    float c = hash21(i + vec2(0.0, 1.0));
    float d = hash21(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
    float a = 0.5;
    float s = 0.0;
    for (int i = 0; i < 4; i++) {
        s += a * vnoise(p);
        p = p * 2.03 + 17.1;
        a *= 0.5;
    }
    return s;
}

// 水面に映る空 (グラデーション + 太陽 + 雲)
vec3 skyRadiance(vec3 dir, vec3 sunDir, float dayW, float twi, vec3 fogC) {
    vec3 zenith = mix(vec3(0.015, 0.025, 0.07), vec3(0.16, 0.36, 0.85), dayW);
    vec3 horizon = mix(vec3(0.04, 0.05, 0.09), vec3(0.62, 0.76, 0.94), dayW);
    horizon = mix(horizon, vec3(1.0, 0.52, 0.24) * 0.85, twi * 0.75);
    horizon = mix(horizon, fogC, 0.25);
    float h = clamp(dir.y, 0.0, 1.0);
    vec3 sky = mix(horizon, zenith, pow(h, 0.55));

    float cosS = max(dot(dir, sunDir), 0.0);
    vec3 sunCol = sunTransmittance(sunDir.y);
    sky += sunCol * (pow(cosS, 24.0) * 0.20 + pow(cosS, 600.0) * 6.0) * dayW;

    // 雲 (ゆっくり円運動 -> GameTime のリセットで飛ばない)
    vec2 drift = 8.0 * vec2(sin(TAU * GameTime), cos(TAU * GameTime));
    vec2 uv = dir.xz / max(dir.y, 0.04) * 0.30 + drift;
    float cov = smoothstep(0.50, 0.74, fbm(uv));
    cov *= smoothstep(0.02, 0.20, dir.y);
    vec3 cloudLit = mix(vec3(0.55, 0.60, 0.72), vec3(1.0, 0.98, 0.94), 0.5 + 0.5 * cosS) * mix(vec3(1.0), sunCol * 1.15, twi);
    vec3 cloudCol = mix(vec3(0.03, 0.04, 0.07), cloudLit, dayW);
    sky = mix(sky, cloudCol, cov * 0.85);
    return sky;
}

// 水面の法線: 大きなうねり + 距離で消える細かいさざ波
void addWave(inout vec2 g, vec2 p, vec2 d, float k, float cycles, float slope) {
    d = normalize(d);
    float ph = k * dot(d, p) - TAU * cycles * GameTime;
    g += d * (slope * cos(ph));
}

vec3 waterNormal(vec2 p, float dist) {
    float fine = 1.0 - smoothstep(20.0, 70.0, dist);
    vec2 g = vec2(0.0);
    addWave(g, p, vec2(0.90, 0.44), TAU / 13.0, 120.0, 0.040);
    addWave(g, p, vec2(-0.50, 0.87), TAU / 9.0, 160.0, 0.036);
    addWave(g, p, vec2(0.20, -0.98), TAU / 5.5, 260.0, 0.034 * fine);
    addWave(g, p, vec2(0.80, -0.60), TAU / 3.1, 420.0, 0.022 * fine);
    return normalize(vec3(-g.x, 1.0, -g.y));
}

void main() {
    vec3 dpx = dFdx(viewPosV);
    vec3 dpy = dFdy(viewPosV);

    vec4 color = (UseRgss == 1 ? sampleRGSS(Sampler0, texCoord0, 1.0f / vec2(TextureSize)) : sampleNearest(Sampler0, texCoord0, 1.0f / vec2(TextureSize))) * vertexColor;
    color = mix(FogColor * vec4(1, 1, 1, color.a), color, ChunkVisibility);
#ifdef ALPHA_CUTOUT
    if (color.a < ALPHA_CUTOUT) {
        discard;
    }
#endif

    // ---- 幾何法線 ----
    mat3 V2W = transpose(mat3(ModelViewMat));
    vec3 nc = cross(dpx, dpy);
    vec3 Nv = nc / max(length(nc), 1e-6);
    if (dot(Nv, viewPosV) > 0.0) Nv = -Nv;
    vec3 Nw = normalize(V2W * Nv);

    // ---- 時間帯 ----
    vec3 sunDir = getSunDir();
    float dayW = smoothstep(-0.10, 0.15, sunDir.y);
    float twi = exp(-abs(sunDir.y) * 5.0) * dayW;
    vec3 sunCol = sunTransmittance(sunDir.y);
    vec3 sunTone = sunCol / max(luma(sunCol), 1e-3);

    // ---- 影: 空の光(スカイライト)で日向と日陰を分ける ----
    // 木の下・屋根の下・崖の陰・洞窟入口は空光が下がるので陰になる
    float open = smoothstep(0.30, 0.80, skyLightV);          // 屋外度
    float sunReach = smoothstep(0.80, 0.97, skyLightV);      // 直射が届くか
    float ndl = dot(Nw, sunDir);
    float facing = smoothstep(-0.10, 0.55, ndl);             // 太陽に向く面
    float lit = sunReach * facing;

    vec3 litMul = sunTone * (0.95 + 0.22 * max(ndl, 0.0));
    vec3 shadeMul = mix(vec3(0.80, 0.88, 1.02), vec3(0.74, 0.82, 1.02), twi) * 0.92;
    vec3 dayMul = mix(shadeMul, litMul, lit);
    vec3 nightMul = vec3(0.86, 0.93, 1.10);
    vec3 tone = mix(nightMul, dayMul, dayW);
    color.rgb *= mix(vec3(1.0), tone, open * SUN_SHADOW);

    // ---- 水面: 波の法線 + 空の鏡面反射 + 太陽のきらめき ----
    float dist = length(viewPosV);
    float waterMask = clamp(waterV, 0.0, 1.0) * smoothstep(0.75, 0.92, Nw.y);
    if (waterMask > 0.001) {
        vec3 Nwave = waterNormal(worldPosV.xz, dist);
        vec3 Nvw = normalize(mat3(ModelViewMat) * Nwave);
        vec3 I = normalize(viewPosV);
        float cosT = max(dot(-I, Nvw), 0.0);
        float F = clamp(0.06 + 0.94 * pow(1.0 - cosT, 3.0), 0.0, 0.92);
        vec3 Rw = normalize(V2W * reflect(I, Nvw));
        Rw.y = max(Rw.y, 0.01);
        float skyVis = smoothstep(0.55, 0.95, skyLightV);
        vec3 refl = skyRadiance(Rw, sunDir, dayW, twi, FogColor.rgb);

        vec3 Lv = normalize(mat3(ModelViewMat) * sunDir);
        vec3 H = normalize(Lv - I);
        float glit = pow(max(dot(Nvw, H), 0.0), 300.0) * 3.0 * F * (1.0 - smoothstep(30.0, 90.0, dist) * 0.7);

        float k = waterMask * skyVis * WATER_REFLECTION;
        color.rgb *= mix(1.0, 0.85, k);                       // 水自体の深み
        color.rgb = mix(color.rgb, refl, F * k);
        color.rgb += sunCol * glit * dayW * k;
        color.a = mix(color.a, 1.0, F * k);
    }

    // ---- 仕上げ: フィルミックなトーンカーブ + 彩度 ----
    color.rgb = mix(vec3(luma(color.rgb)), color.rgb, SATURATION);
    color.rgb = hableTonemap(color.rgb * 2.2 * EXPOSURE) / hableTonemap(vec3(2.2));

    // ---- 大気散乱フォグ ----
    float fogValue = total_fog_value(sphericalVertexDistance, cylindricalVertexDistance, FogEnvironmentalStart, FogEnvironmentalEnd, FogRenderDistanceStart, FogRenderDistanceEnd);
    float airFog = step(0.0, FogEnvironmentalStart) * smoothstep(10.0, 40.0, FogEnvironmentalEnd);
    vec3 viewDirW = normalize(V2W * viewPosV);
    float cosS = max(dot(viewDirW, sunDir), 0.0);
    float mie = pow(cosS, 6.0) * 0.35 + pow(cosS, 48.0) * 0.8;
    vec3 fogC = FogColor.rgb;
    fogC += sunCol * mie * 0.08 * dayW * airFog * FOG_SCATTER;
    fogC = mix(fogC, fogC * vec3(1.12, 0.94, 0.82), twi * 0.5 * airFog * FOG_SCATTER);

    fragColor = vec4(mix(color.rgb, fogC, fogValue * FogColor.a), color.a);
}

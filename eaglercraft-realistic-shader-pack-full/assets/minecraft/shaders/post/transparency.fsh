#version 330

// Realistic Post (Improved Transparency チェーン上書き)
// 画面全体の深度を使う追加処理:
//   ・SSAO (接触影 / 隅の陰影)
//   ・水面のスクリーンスペース反射 (木・地形・建物が水に映る)
//   ・ブルーム / ビネット
// 要: オプション > ビデオ > 「透明度の改善 (Improved Transparency)」ON

uniform sampler2D MainSampler;
uniform sampler2D MainDepthSampler;
uniform sampler2D TranslucentSampler;
uniform sampler2D TranslucentDepthSampler;
uniform sampler2D ItemEntitySampler;
uniform sampler2D ItemEntityDepthSampler;
uniform sampler2D ParticlesSampler;
uniform sampler2D ParticlesDepthSampler;
uniform sampler2D WeatherSampler;
uniform sampler2D WeatherDepthSampler;
uniform sampler2D CloudsSampler;
uniform sampler2D CloudsDepthSampler;

in vec2 texCoord;

#define TAU 6.28318530718
#define NEAR 0.05
#define FAR 512.0               // 描画距離に合わせて調整 (近い所の精度に影響)
#define TAN_HALF_FOV 0.7002     // 垂直FOV 70 度 (FOV を変えたら tan(FOV/2) に)

#define SSAO_STRENGTH 0.75      // 0.0 で無効
#define SSAO_RADIUS 0.8         // ブロック単位
#define SSR_STRENGTH 1.0        // 0.0 で無効
#define BLOOM_STRENGTH 0.22     // 0.0 で無効
#define VIGNETTE 0.22           // 0.0 で無効

vec4 color_layers[6] = vec4[](vec4(0.0), vec4(0.0), vec4(0.0), vec4(0.0), vec4(0.0), vec4(0.0));
float depth_layers[6] = float[](0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
int active_layers = 0;

out vec4 fragColor;

void try_insert(vec4 color, float depth) {
    if (color.a == 0.0) {
        return;
    }

    color_layers[active_layers] = color;
    depth_layers[active_layers] = depth;

    int jj = active_layers++;
    int ii = jj - 1;
    while (jj > 0 && depth_layers[jj] < depth_layers[ii]) {
        float depthTemp = depth_layers[ii];
        depth_layers[ii] = depth_layers[jj];
        depth_layers[jj] = depthTemp;

        vec4 colorTemp = color_layers[ii];
        color_layers[ii] = color_layers[jj];
        color_layers[jj] = colorTemp;

        jj = ii--;
    }
}

vec3 blend(vec3 dst, vec4 src) {
    return (dst * (1.0 - src.a)) + src.rgb;
}

float linZ(float d) {
    return 2.0 * NEAR * FAR / (FAR + NEAR - (2.0 * d - 1.0) * (FAR - NEAR));
}

vec3 viewPosFrom(vec2 uv, float z, float aspect) {
    vec2 ndc = uv * 2.0 - 1.0;
    return vec3(ndc.x * TAN_HALF_FOV * aspect * z, ndc.y * TAN_HALF_FOV * z, -z);
}

float noiseIGN(vec2 p) {
    return fract(52.9829189 * fract(dot(p, vec2(0.06711056, 0.00583715))));
}

vec2 vogel(int i, int n, float phi) {
    float r = sqrt((float(i) + 0.5) / float(n));
    float th = float(i) * 2.399963 + phi;
    return r * vec2(cos(th), sin(th));
}

float luma(vec3 c) {
    return dot(c, vec3(0.2126, 0.7152, 0.0722));
}

// ---- SSAO ----
float ssao(vec2 uv, float z, float aspect, vec2 res, float noise) {
    float rad = SSAO_RADIUS;
    vec2 ruv = vec2(rad / (z * TAN_HALF_FOV * aspect), rad / (z * TAN_HALF_FOV)) * 0.5;
    ruv = clamp(ruv, 2.0 / res, 48.0 / res);
    float occ = 0.0;
    for (int i = 0; i < 16; i++) {
        vec2 s = uv + vogel(i, 16, noise * TAU) * ruv;
        if (s.x < 0.0 || s.x > 1.0 || s.y < 0.0 || s.y > 1.0) continue;
        float zs = linZ(texture(MainDepthSampler, s).r);
        float dz = z - zs;
        float range = rad * 1.5;
        if (dz > 0.03 && dz < range) {
            occ += 1.0 - dz / range;
        }
    }
    float a = clamp(occ / 16.0 * 2.0, 0.0, 1.0);
    return 1.0 - SSAO_STRENGTH * a;
}

// ---- 水面のスクリーンスペース反射 ----
// 戻り値: rgb = 映る色, a = 反射の有効度 (0 = ヒットせず)
vec4 ssr(vec3 P, vec3 N, float aspect, float noise) {
    vec3 V = normalize(P);
    vec3 R = reflect(V, N);
    if (R.z > 0.2) return vec4(0.0);          // カメラ側へ戻る向きは不可

    vec3 pos = P + N * 0.04;
    float stepLen = 0.30;
    for (int i = 0; i < 48; i++) {
        pos += R * stepLen * (0.85 + 0.3 * noise);
        stepLen *= 1.09;
        float z = -pos.z;
        if (z < NEAR) break;
        vec2 uv = vec2(pos.x / (z * TAN_HALF_FOV * aspect), pos.y / (z * TAN_HALF_FOV)) * 0.5 + 0.5;
        if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) break;
        float d = texture(MainDepthSampler, uv).r;
        if (d >= 0.99999) continue;           // 空はヒット扱いにしない
        float diff = z - linZ(d);
        if (diff > 0.0 && diff < stepLen * 1.6 + 0.08) {
            float e = min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y));
            float edge = smoothstep(0.0, 0.08, e);
            float dist = smoothstep(0.0, 1.0, 1.0 - float(i) / 48.0);
            return vec4(texture(MainSampler, uv).rgb, edge * dist);
        }
    }
    return vec4(0.0);
}

void main() {
    vec2 res = vec2(textureSize(MainSampler, 0));
    float aspect = res.x / res.y;
    float noise = noiseIGN(gl_FragCoord.xy);

    float dMain = texture(MainDepthSampler, texCoord).r;
    vec4 tr = texture(TranslucentSampler, texCoord);
    float dTr = texture(TranslucentDepthSampler, texCoord).r;

    // 微分は分岐の外で計算する
    float zTr = linZ(dTr);
    vec3 Pt = viewPosFrom(texCoord, zTr, aspect);
    vec3 dpx = dFdx(Pt);
    vec3 dpy = dFdy(Pt);

    // ---- 不透明レイヤー + SSAO ----
    vec3 mainCol = texture(MainSampler, texCoord).rgb;
    if (dMain < 0.99999 && SSAO_STRENGTH > 0.0) {
        float zM = linZ(dMain);
        mainCol *= ssao(texCoord, zM, aspect, res, noise);
    }
    color_layers[0] = vec4(mainCol, 1.0);
    depth_layers[0] = dMain;
    active_layers = 1;

    // ---- 水面 SSR (青みのある半透明 = 水と判定) ----
    if (tr.a > 0.05 && dTr < dMain && SSR_STRENGTH > 0.0) {
        vec3 straight = tr.rgb / tr.a;
        bool waterLike = straight.b >= straight.r * 1.05;
        float edgeLen = length(dpx) + length(dpy);
        if (waterLike && edgeLen < zTr * 0.05) {
            vec3 N = normalize(cross(dpx, dpy));
            if (dot(N, Pt) > 0.0) N = -N;
            float cosT = max(dot(-normalize(Pt), N), 0.0);
            float F = clamp(0.06 + 0.94 * pow(1.0 - cosT, 3.0), 0.0, 0.92);
            vec4 r = ssr(Pt, N, aspect, noise);
            float w = F * r.a * SSR_STRENGTH;
            straight = mix(straight, r.rgb, w);
            float a2 = mix(tr.a, 1.0, w * 0.9);
            tr = vec4(straight * a2, a2);
        }
    }

    try_insert(tr, dTr);
    try_insert(texture(ItemEntitySampler, texCoord), texture(ItemEntityDepthSampler, texCoord).r);
    try_insert(texture(ParticlesSampler, texCoord), texture(ParticlesDepthSampler, texCoord).r);
    try_insert(texture(WeatherSampler, texCoord), texture(WeatherDepthSampler, texCoord).r);
    try_insert(texture(CloudsSampler, texCoord), texture(CloudsDepthSampler, texCoord).r);

    vec3 texelAccum = color_layers[0].rgb;
    for (int ii = 1; ii < active_layers; ++ii) {
        texelAccum = blend(texelAccum, color_layers[ii]);
    }

    // ---- ブルーム (明るい部分のにじみ) ----
    if (BLOOM_STRENGTH > 0.0) {
        vec2 texel = 1.0 / res;
        vec3 glow = vec3(0.0);
        for (int i = 0; i < 12; i++) {
            vec2 o = vogel(i, 12, noise * TAU);
            vec3 c1 = texture(MainSampler, texCoord + o * texel * 10.0).rgb;
            vec3 c2 = texture(MainSampler, texCoord + o * texel * 30.0).rgb;
            glow += max(c1 - 0.78, 0.0) * 1.0 + max(c2 - 0.78, 0.0) * 0.6;
        }
        texelAccum += glow / 12.0 * BLOOM_STRENGTH * 2.0;
    }

    // ---- ビネット ----
    vec2 q = texCoord * 2.0 - 1.0;
    texelAccum *= 1.0 - VIGNETTE * dot(q, q) * 0.5;

    fragColor = vec4(texelAccum, 1.0);
}

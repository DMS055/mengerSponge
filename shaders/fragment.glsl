#version 330 core
layout(location = 0) out vec4 fragColor;

uniform vec2 u_resolution;
uniform float u_time;

const int MAX_STEPS = 300;
const float MAX_DIST = 50;
const float EPSILON = 0.0001;
const float PI = acos(-1.0);


mat2 rot(float a) {
    float ca = cos(a);
    float sa = sin(a);
    return mat2(ca, sa, -sa, ca);
}


float getSphere(vec3 p, float r) {
    return length(p) - r;
}


vec4 map(vec3 p) {
    float d = 0.0;
    vec3 col = vec3(1);

    d = getSphere(p, 0.5);

    return vec4(col, d * 0.9);
}


vec4 rayMarch(vec3 ro, vec3 rd, int steps) {
    float dist; vec3 p; vec3 col;
    for (int i; i < steps; i++) {
        p = ro + rd * dist;
        vec4 res = map(p);
        col = res.rgb;
        if (res.w < EPSILON) break;
        dist += res.w;
        if (dist > MAX_DIST) break;
    }
    return vec4(col, dist);
}


float getAO(vec3 pos, vec3 norm) {
    float AO_SAMPLES = 10.0;
    float AO_FACTOR = 1.0;
    float result = 1.0;
    float s = -AO_SAMPLES;
    float unit = 1.0 / AO_SAMPLES;
    for (float i = unit; i < 1.0; i += unit) {
        result -= pow(1.4, i * s) * (i - map(pos + i * norm).w);
    }
    return result * AO_FACTOR;
}


vec3 getNormal(vec3 p) {
    vec2 e = vec2(EPSILON, 0.0);
    vec3 n = map(p).w - vec3(map(p - e.xyy).w, map(p - e.yxy).w, map(p - e.yyx).w);
    return normalize(n);
}


vec3 render(vec2 uv) {
    vec3 col = vec3(0);
    vec3 ro = vec3(0, 0, -1.9);
    vec3 rd = normalize(vec3(uv, 2.0));

    vec4 res = rayMarch(ro, rd, MAX_STEPS);

    if (res.w < MAX_DIST) {
        vec3 p = ro + rd * res.w;
        vec3 normal = getNormal(p);

        // shading
        float diff = 0.7 * max(0.0, dot(normal, -rd));
        vec3 ref = reflect(rd, normal);
        float spec = max(0.0, pow(dot(ref, -rd), 32.0));
        float ao = getAO(p, normal);
        col += (spec + diff) * ao * res.rgb;
    }
    return col;
}



void main() {
    vec2 uv = 2.0 * gl_FragCoord.xy - u_resolution.xy;
    uv /= u_resolution.y;
    vec3 col = render(uv);

    fragColor = vec4(sqrt(col), 1.0);
}
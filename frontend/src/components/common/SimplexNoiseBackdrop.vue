<script setup lang="ts">
import { onBeforeUnmount, onMounted, ref, watch } from 'vue'

const VERT_SHADER = `
  attribute vec2 position;
  varying vec2 vUv;

  void main() {
    vUv = position * 0.5 + 0.5;
    gl_Position = vec4(position, 0.0, 1.0);
  }
`

const FRAG_SHADER = `
  precision highp float;

  uniform vec2 uResolution;
  uniform float uTime;
  uniform vec3 uBase;
  uniform vec3 uGlowA;
  uniform vec3 uGlowB;
  uniform float uMotion;
  uniform vec2 uPointer;
  uniform float uPointerMix;
  varying vec2 vUv;

  vec3 mod289(vec3 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
  }

  vec2 mod289(vec2 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
  }

  vec3 permute(vec3 x) {
    return mod289(((x * 34.0) + 1.0) * x);
  }

  float snoise(vec2 v) {
    const vec4 C = vec4(
      0.211324865405187,
      0.366025403784439,
     -0.577350269189626,
      0.024390243902439
    );

    vec2 i = floor(v + dot(v, C.yy));
    vec2 x0 = v - i + dot(i, C.xx);
    vec2 i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
    vec4 x12 = x0.xyxy + C.xxzz;
    x12.xy -= i1;

    i = mod289(i);
    vec3 p = permute(
      permute(i.y + vec3(0.0, i1.y, 1.0))
      + i.x + vec3(0.0, i1.x, 1.0)
    );

    vec3 m = max(
      0.5 - vec3(
        dot(x0, x0),
        dot(x12.xy, x12.xy),
        dot(x12.zw, x12.zw)
      ),
      0.0
    );
    m = m * m;
    m = m * m;

    vec3 x = 2.0 * fract(p * C.www) - 1.0;
    vec3 h = abs(x) - 0.5;
    vec3 ox = floor(x + 0.5);
    vec3 a0 = x - ox;

    m *= 1.79284291400159 - 0.85373472095314 * (a0 * a0 + h * h);

    vec3 g;
    g.x = a0.x * x0.x + h.x * x0.y;
    g.yz = a0.yz * x12.xz + h.yz * x12.yw;
    return 130.0 * dot(m, g);
  }

  void main() {
    vec2 uv = vUv;
    vec2 aspect = vec2(uResolution.x / max(uResolution.y, 1.0), 1.0);
    vec2 p = (uv - 0.5) * aspect;
    float time = uTime * uMotion * 0.58;

    float warpA = snoise(p * 1.0 + vec2(time * 1.02, -time * 0.62));
    float warpB = snoise((p + vec2(2.7, -1.9)) * 1.12 - vec2(time * 0.78, time * 0.52));
    vec2 drift = vec2(time * 0.096, -time * 0.056);
    vec2 sweep = vec2(
      sin(time * 0.22 + p.y * 1.12),
      cos(time * 0.18 - p.x * 0.92)
    ) * 0.064;
    vec2 flow = p + drift + sweep + vec2(warpA, warpB) * 0.17;

    vec2 pointer = (uPointer - 0.5) * aspect;
    vec2 delta = flow - pointer;
    float radius = max(dot(delta, delta), 0.0001);
    float press = exp(-radius * 22.0) * uPointerMix;
    flow += normalize(delta) * press * 0.085;
    flow += vec2(
      snoise(flow * 1.8 + vec2(time * 0.45, time * 0.12)),
      snoise(flow.yx * 1.8 + vec2(-time * 0.28, time * 0.36))
    ) * press * 0.018;

    float ribbon = snoise(flow * 1.54 + vec2(time * 0.94, -time * 0.56));
    float cloud = snoise((flow + vec2(-2.3, 1.6)) * 1.02 - vec2(time * 0.44, time * 0.54));
    float mist = snoise((flow + vec2(1.8, 3.2)) * 0.84 + vec2(time * 0.34, -time * 0.26));
    float tide = sin(flow.x * 1.32 - flow.y * 0.52 + time * 0.82);
    float swell = cos(flow.y * 1.04 + flow.x * 0.36 - time * 0.64);

    float bandA = smoothstep(-0.56, 0.64, ribbon + tide * 0.2);
    float bandB = smoothstep(-0.5, 0.7, cloud + swell * 0.18);
    float bandC = smoothstep(-0.4, 0.76, mist + ribbon * 0.24 + tide * 0.1);

    vec3 color = uBase;
    color = mix(color, uGlowA, bandA * 0.58);
    color = mix(color, uGlowB, bandB * 0.48);
    color += bandC * 0.086;

    float centerBloom = smoothstep(0.98, 0.12, distance(flow, vec2(0.02, -0.03)));
    color += centerBloom * 0.04;

    float grain = snoise((uv * uResolution / min(uResolution.x, uResolution.y)) * 10.0 + time * 0.08);
    color += grain * 0.006;

    gl_FragColor = vec4(color, 1.0);
  }
`

function compileShader(gl: WebGLRenderingContext, type: number, source: string) {
  const shader = gl.createShader(type)
  if (!shader) return null
  gl.shaderSource(shader, source)
  gl.compileShader(shader)
  if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
    console.error(gl.getShaderInfoLog(shader))
    gl.deleteShader(shader)
    return null
  }
  return shader
}

function createProgram(gl: WebGLRenderingContext, vertexSource: string, fragmentSource: string) {
  const vertex = compileShader(gl, gl.VERTEX_SHADER, vertexSource)
  const fragment = compileShader(gl, gl.FRAGMENT_SHADER, fragmentSource)
  if (!vertex || !fragment) return null

  const program = gl.createProgram()
  if (!program) return null
  gl.attachShader(program, vertex)
  gl.attachShader(program, fragment)
  gl.linkProgram(program)
  if (!gl.getProgramParameter(program, gl.LINK_STATUS)) {
    console.error(gl.getProgramInfoLog(program))
    gl.deleteProgram(program)
    return null
  }
  return program
}

const probeCtx =
  typeof document !== 'undefined'
    ? document.createElement('canvas').getContext('2d')
    : null

function resolveColor(color: string) {
  if (!probeCtx) return [0.5, 0.5, 0.5] as const
  probeCtx.fillStyle = color
  probeCtx.fillRect(0, 0, 1, 1)
  const [r, g, b] = probeCtx.getImageData(0, 0, 1, 1).data
  return [r / 255, g / 255, b / 255] as const
}

interface NoiseProps {
  className?: string
  baseColor?: string
  glowColorA?: string
  glowColorB?: string
}

const props = withDefaults(defineProps<NoiseProps>(), {
  className: '',
  baseColor: '#f6edf1',
  glowColorA: '#f9dfe7',
  glowColorB: '#e7eefb',
})

const canvasRef = ref<HTMLCanvasElement | null>(null)
const enabled = ref(true)

let resizeObserver: ResizeObserver | null = null
let mediaQuery: MediaQueryList | null = null
let mediaListener: ((event: MediaQueryListEvent) => void) | null = null
let rafId = 0

let gl: WebGLRenderingContext | null = null
let program: WebGLProgram | null = null
let positionBuffer: WebGLBuffer | null = null
let positionLoc = -1
let resolutionLoc: WebGLUniformLocation | null = null
let timeLoc: WebGLUniformLocation | null = null
let baseLoc: WebGLUniformLocation | null = null
let glowALoc: WebGLUniformLocation | null = null
let glowBLoc: WebGLUniformLocation | null = null
let motionLoc: WebGLUniformLocation | null = null
let pointerLoc: WebGLUniformLocation | null = null
let pointerMixLoc: WebGLUniformLocation | null = null
let startTime = 0
let reduceMotion = false
let lastFrameTime = 0
const frameInterval = 1000 / 30
let pointerX = 0.5
let pointerY = 0.5
let pointerTargetX = 0.5
let pointerTargetY = 0.5
let pointerMix = 0.12
let pointerTargetMix = 0.12
let pointerDecayTimer: ReturnType<typeof setTimeout> | null = null
let onPointerMove: ((event: PointerEvent) => void) | null = null

function applyResolvedColors() {
  if (!gl || !program) return
  const base = resolveColor(props.baseColor)
  const glowA = resolveColor(props.glowColorA)
  const glowB = resolveColor(props.glowColorB)
  gl.useProgram(program)
  gl.uniform3f(baseLoc, base[0], base[1], base[2])
  gl.uniform3f(glowALoc, glowA[0], glowA[1], glowA[2])
  gl.uniform3f(glowBLoc, glowB[0], glowB[1], glowB[2])
}

function renderFrame(now: number) {
  if (!gl || !program || !canvasRef.value) return

  if (!startTime) startTime = now
  if (!reduceMotion && lastFrameTime && now - lastFrameTime < frameInterval) {
    rafId = requestAnimationFrame(renderFrame)
    return
  }
  lastFrameTime = now
  const elapsed = (now - startTime) / 1000
  pointerX += (pointerTargetX - pointerX) * 0.08
  pointerY += (pointerTargetY - pointerY) * 0.08
  pointerMix += (pointerTargetMix - pointerMix) * 0.085

  gl.useProgram(program)
  gl.bindBuffer(gl.ARRAY_BUFFER, positionBuffer)
  gl.enableVertexAttribArray(positionLoc)
  gl.vertexAttribPointer(positionLoc, 2, gl.FLOAT, false, 0, 0)
  gl.uniform2f(resolutionLoc, canvasRef.value.width, canvasRef.value.height)
  gl.uniform1f(timeLoc, elapsed)
  gl.uniform1f(motionLoc, reduceMotion ? 0.0 : 1.0)
  gl.uniform2f(pointerLoc, pointerX, pointerY)
  gl.uniform1f(pointerMixLoc, reduceMotion ? 0.0 : pointerMix)
  gl.viewport(0, 0, canvasRef.value.width, canvasRef.value.height)
  gl.drawArrays(gl.TRIANGLES, 0, 6)

  if (!reduceMotion) {
    rafId = requestAnimationFrame(renderFrame)
  }
}

function resizeCanvas() {
  if (!canvasRef.value || !gl) return
  const rect = canvasRef.value.getBoundingClientRect()
  const dpr = Math.min(window.devicePixelRatio, 1.1)
  const renderScale = reduceMotion ? 0.5 : 0.58
  canvasRef.value.width = Math.max(1, Math.round(rect.width * dpr * renderScale))
  canvasRef.value.height = Math.max(1, Math.round(rect.height * dpr * renderScale))
  renderFrame(performance.now())
}

function destroy() {
  cancelAnimationFrame(rafId)
  resizeObserver?.disconnect()
  resizeObserver = null
  if (pointerDecayTimer) {
    clearTimeout(pointerDecayTimer)
    pointerDecayTimer = null
  }
  if (onPointerMove) {
    window.removeEventListener('pointermove', onPointerMove)
    onPointerMove = null
  }
  if (mediaQuery && mediaListener) {
    mediaQuery.removeEventListener('change', mediaListener)
  }
  mediaListener = null
  mediaQuery = null
  if (gl) {
    if (positionBuffer) gl.deleteBuffer(positionBuffer)
    if (program) gl.deleteProgram(program)
  }
  gl = null
  program = null
  positionBuffer = null
}

onMounted(() => {
  const canvas = canvasRef.value
  if (!canvas) return

  const context = canvas.getContext('webgl', {
    alpha: true,
    antialias: false,
    premultipliedAlpha: true,
    powerPreference: 'low-power',
  })

  if (!context) {
    enabled.value = false
    return
  }

  const shaderProgram = createProgram(context, VERT_SHADER, FRAG_SHADER)
  const buffer = context.createBuffer()
  if (!shaderProgram || !buffer) {
    enabled.value = false
    return
  }

  gl = context
  program = shaderProgram
  positionBuffer = buffer

  positionLoc = context.getAttribLocation(shaderProgram, 'position')
  resolutionLoc = context.getUniformLocation(shaderProgram, 'uResolution')
  timeLoc = context.getUniformLocation(shaderProgram, 'uTime')
  baseLoc = context.getUniformLocation(shaderProgram, 'uBase')
  glowALoc = context.getUniformLocation(shaderProgram, 'uGlowA')
  glowBLoc = context.getUniformLocation(shaderProgram, 'uGlowB')
  motionLoc = context.getUniformLocation(shaderProgram, 'uMotion')
  pointerLoc = context.getUniformLocation(shaderProgram, 'uPointer')
  pointerMixLoc = context.getUniformLocation(shaderProgram, 'uPointerMix')

  context.bindBuffer(context.ARRAY_BUFFER, buffer)
  context.bufferData(
    context.ARRAY_BUFFER,
    new Float32Array([-1, -1, 1, -1, -1, 1, -1, 1, 1, -1, 1, 1]),
    context.STATIC_DRAW,
  )

  context.clearColor(0, 0, 0, 0)
  applyResolvedColors()

  mediaQuery = window.matchMedia('(prefers-reduced-motion: reduce)')
  reduceMotion = mediaQuery.matches
  mediaListener = (event: MediaQueryListEvent) => {
    reduceMotion = event.matches
    lastFrameTime = 0
    cancelAnimationFrame(rafId)
    rafId = requestAnimationFrame(renderFrame)
  }
  mediaQuery.addEventListener('change', mediaListener)

  onPointerMove = (event: PointerEvent) => {
    const rect = canvas.getBoundingClientRect()
    if (!rect.width || !rect.height) return
    pointerTargetX = Math.min(Math.max((event.clientX - rect.left) / rect.width, 0), 1)
    pointerTargetY = Math.min(Math.max(1 - (event.clientY - rect.top) / rect.height, 0), 1)
    pointerTargetMix = 0.58
    if (pointerDecayTimer) clearTimeout(pointerDecayTimer)
    pointerDecayTimer = setTimeout(() => {
      pointerTargetMix = 0.12
    }, 80)
  }
  window.addEventListener('pointermove', onPointerMove, { passive: true })

  resizeObserver = new ResizeObserver(() => resizeCanvas())
  resizeObserver.observe(canvas)
  resizeCanvas()
  rafId = requestAnimationFrame(renderFrame)
})

watch(
  () => [props.baseColor, props.glowColorA, props.glowColorB],
  () => applyResolvedColors(),
)

onBeforeUnmount(() => {
  destroy()
})
</script>

<template>
  <canvas
    v-if="enabled"
    ref="canvasRef"
    :class="['simplex-noise-backdrop', className]"
  />
</template>

<style scoped>
.simplex-noise-backdrop {
  position: absolute;
  inset: 0;
  z-index: 0;
  display: block;
  width: 100%;
  height: 100%;
  pointer-events: none;
}
</style>

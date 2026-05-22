<template>
  <teleport to="body">
    <transition name="celebration">
      <div v-if="visible" class="celebration-container" :class="effect">
        <canvas ref="canvas" class="celebration-canvas"></canvas>
      </div>
    </transition>
  </teleport>
</template>

<script setup>
import { ref, watch, onUnmounted } from 'vue'

const props = defineProps({
  visible: { type: Boolean, default: false },
  effect: { 
    type: String, 
    default: 'confetti',
    validator: (v) => ['confetti', 'stars', 'hearts'].includes(v)
  },
  duration: { type: Number, default: 2000 }
})

const emit = defineEmits(['complete'])

const canvas = ref(null)
let animationId = null
let particles = []

const colors = {
  confetti: ['#ff6b6b', '#4ecdc4', '#ffe66d', '#95e1d3', '#f38181', '#aa96da'],
  stars: ['#ffd700', '#ffed4a', '#fff9c4', '#ffeb3b'],
  hearts: ['#ff6b6b', '#ee5a5a', '#ff5252', '#f44336']
}

class Particle {
  constructor(x, y, effect) {
    this.x = x
    this.y = y
    this.vx = (Math.random() - 0.5) * 10
    this.vy = -Math.random() * 15 - 5
    this.gravity = 0.5
    this.rotation = Math.random() * 360
    this.rotationSpeed = (Math.random() - 0.5) * 10
    this.size = Math.random() * 10 + 5
    this.color = colors[effect][Math.floor(Math.random() * colors[effect].length)]
    this.opacity = 1
    this.decay = 0.015
    this.effect = effect
  }

  update() {
    this.vy += this.gravity
    this.x += this.vx
    this.y += this.vy
    this.rotation += this.rotationSpeed
    this.opacity -= this.decay
    return this.opacity > 0
  }

  draw(ctx) {
    ctx.save()
    ctx.translate(this.x, this.y)
    ctx.rotate((this.rotation * Math.PI) / 180)
    ctx.globalAlpha = this.opacity
    ctx.fillStyle = this.color

    if (this.effect === 'confetti') {
      ctx.fillRect(-this.size / 2, -this.size / 4, this.size, this.size / 2)
    } else if (this.effect === 'stars') {
      this.drawStar(ctx, 0, 0, 5, this.size, this.size / 2)
    } else if (this.effect === 'hearts') {
      this.drawHeart(ctx, 0, 0, this.size)
    }

    ctx.restore()
  }

  drawStar(ctx, cx, cy, spikes, outerRadius, innerRadius) {
    let rot = (Math.PI / 2) * 3
    let x = cx
    let y = cy
    const step = Math.PI / spikes

    ctx.beginPath()
    ctx.moveTo(cx, cy - outerRadius)
    for (let i = 0; i < spikes; i++) {
      x = cx + Math.cos(rot) * outerRadius
      y = cy + Math.sin(rot) * outerRadius
      ctx.lineTo(x, y)
      rot += step
      x = cx + Math.cos(rot) * innerRadius
      y = cy + Math.sin(rot) * innerRadius
      ctx.lineTo(x, y)
      rot += step
    }
    ctx.lineTo(cx, cy - outerRadius)
    ctx.closePath()
    ctx.fill()
  }

  drawHeart(ctx, x, y, size) {
    ctx.beginPath()
    ctx.moveTo(x, y + size / 4)
    ctx.bezierCurveTo(x, y, x - size / 2, y, x - size / 2, y + size / 4)
    ctx.bezierCurveTo(x - size / 2, y + size / 2, x, y + size * 0.75, x, y + size)
    ctx.bezierCurveTo(x, y + size * 0.75, x + size / 2, y + size / 2, x + size / 2, y + size / 4)
    ctx.bezierCurveTo(x + size / 2, y, x, y, x, y + size / 4)
    ctx.fill()
  }
}

function initCanvas() {
  if (!canvas.value) return
  
  const ctx = canvas.value.getContext('2d')
  canvas.value.width = window.innerWidth
  canvas.value.height = window.innerHeight
  
  particles = []
  const centerX = canvas.value.width / 2
  const centerY = canvas.value.height / 2
  
  for (let i = 0; i < 50; i++) {
    particles.push(new Particle(centerX, centerY, props.effect))
  }
  
  animate(ctx)
}

function animate(ctx) {
  ctx.clearRect(0, 0, canvas.value.width, canvas.value.height)
  
  particles = particles.filter(p => {
    p.draw(ctx)
    return p.update()
  })
  
  if (particles.length > 0) {
    animationId = requestAnimationFrame(() => animate(ctx))
  } else {
    emit('complete')
  }
}

watch(() => props.visible, (newVal) => {
  if (newVal) {
    setTimeout(initCanvas, 50)
    setTimeout(() => {
      emit('complete')
    }, props.duration)
  } else {
    if (animationId) {
      cancelAnimationFrame(animationId)
    }
  }
})

onUnmounted(() => {
  if (animationId) {
    cancelAnimationFrame(animationId)
  }
})
</script>

<style scoped>
.celebration-container {
  position: fixed;
  inset: 0;
  pointer-events: none;
  z-index: 9999;
}

.celebration-canvas {
  width: 100%;
  height: 100%;
}

.celebration-enter-active,
.celebration-leave-active {
  transition: opacity 0.3s ease;
}

.celebration-enter-from,
.celebration-leave-to {
  opacity: 0;
}
</style>

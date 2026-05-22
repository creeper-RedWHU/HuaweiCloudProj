import { ref, onMounted, onUnmounted } from 'vue'

export function useRipple() {
  const ripples = ref([])
  let rippleId = 0

  function createRipple(event, color = 'rgba(255, 255, 255, 0.3)') {
    const target = event.currentTarget
    const rect = target.getBoundingClientRect()
    
    const x = event.clientX - rect.left
    const y = event.clientY - rect.top
    
    const size = Math.max(rect.width, rect.height) * 2
    
    const ripple = {
      id: ++rippleId,
      x,
      y,
      size,
      color
    }
    
    ripples.value.push(ripple)
    
    setTimeout(() => {
      removeRipple(ripple.id)
    }, 600)
    
    return ripple
  }

  function removeRipple(id) {
    const index = ripples.value.findIndex(r => r.id === id)
    if (index !== -1) {
      ripples.value.splice(index, 1)
    }
  }

  function getRippleStyle(ripple) {
    return {
      left: `${ripple.x - ripple.size / 2}px`,
      top: `${ripple.y - ripple.size / 2}px`,
      width: `${ripple.size}px`,
      height: `${ripple.size}px`,
      backgroundColor: ripple.color
    }
  }

  return {
    ripples,
    createRipple,
    removeRipple,
    getRippleStyle
  }
}

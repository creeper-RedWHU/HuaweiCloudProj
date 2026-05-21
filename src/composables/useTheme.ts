import { ref, watch, onMounted } from 'vue'
import { themes, getThemeById, defaultTheme, type ThemeConfig } from '../config/themes'
import { applyTheme } from '../utils/cssVariables'

const STORAGE_KEY = 'task-kanban-theme'

const currentTheme = ref<ThemeConfig>(defaultTheme)
const isPreviewing = ref(false)
const previewTheme = ref<ThemeConfig | null>(null)

export function useTheme() {
  function loadSavedTheme() {
    try {
      const savedId = localStorage.getItem(STORAGE_KEY)
      if (savedId) {
        const theme = getThemeById(savedId)
        if (theme) {
          currentTheme.value = theme
          applyTheme(theme)
          return
        }
      }
    } catch (e) {
      console.warn('Failed to load saved theme:', e)
    }
    currentTheme.value = defaultTheme
    applyTheme(defaultTheme)
  }

  function setTheme(themeId: string) {
    const theme = getThemeById(themeId)
    if (theme) {
      currentTheme.value = theme
      applyTheme(theme)
      saveTheme(themeId)
    }
  }

  function saveTheme(themeId: string) {
    try {
      localStorage.setItem(STORAGE_KEY, themeId)
    } catch (e) {
      console.warn('Failed to save theme:', e)
    }
  }

  function preview(themeId: string) {
    const theme = getThemeById(themeId)
    if (theme && theme.id !== currentTheme.value.id) {
      isPreviewing.value = true
      previewTheme.value = theme
      applyTheme(theme)
    }
  }

  function stopPreview() {
    if (isPreviewing.value) {
      isPreviewing.value = false
      previewTheme.value = null
      applyTheme(currentTheme.value)
    }
  }

  function cycleTheme() {
    const currentIndex = themes.findIndex(t => t.id === currentTheme.value.id)
    const nextIndex = (currentIndex + 1) % themes.length
    setTheme(themes[nextIndex].id)
  }

  onMounted(() => {
    loadSavedTheme()
  })

  return {
    currentTheme,
    isPreviewing,
    previewTheme,
    themes,
    setTheme,
    preview,
    stopPreview,
    cycleTheme,
    loadSavedTheme
  }
}

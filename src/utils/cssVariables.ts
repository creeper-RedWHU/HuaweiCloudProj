export function applyThemeColors(colors: Record<string, string>): void {
  const root = document.documentElement
  Object.entries(colors).forEach(([key, value]) => {
    const cssVarName = `--color-${kebabCase(key)}`
    root.style.setProperty(cssVarName, value)
  })
}

export function applyTheme(theme: { colors: Record<string, string> }): void {
  applyThemeColors(theme.colors)
}

export function getCssVariable(name: string): string {
  return getComputedStyle(document.documentElement).getPropertyValue(name).trim()
}

export function setCssVariable(name: string, value: string): void {
  document.documentElement.style.setProperty(name, value)
}

function kebabCase(str: string): string {
  return str.replace(/([A-Z])/g, '-$1').toLowerCase()
}

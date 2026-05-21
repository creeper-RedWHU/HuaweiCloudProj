export interface ThemeColors {
  primary: string
  primaryLight: string
  primaryDark: string
  secondary: string
  success: string
  warning: string
  danger: string
  info: string
  background: string
  backgroundSecondary: string
  surface: string
  surfaceHover: string
  text: string
  textSecondary: string
  textMuted: string
  border: string
  borderLight: string
  shadow: string
  shadowLight: string
}

export interface ThemeConfig {
  id: string
  name: string
  icon: string
  colors: ThemeColors
}

export const lightTheme: ThemeConfig = {
  id: 'light',
  name: '亮色主题',
  icon: '☀️',
  colors: {
    primary: '#4a9eff',
    primaryLight: '#6db3ff',
    primaryDark: '#3a8eef',
    secondary: '#f5a623',
    success: '#7ed321',
    warning: '#f5a623',
    danger: '#ff4757',
    info: '#4a9eff',
    background: '#f0f2f5',
    backgroundSecondary: '#e8eaed',
    surface: '#ffffff',
    surfaceHover: '#f8f9fa',
    text: '#333333',
    textSecondary: '#666666',
    textMuted: '#999999',
    border: '#e0e0e0',
    borderLight: '#f0f0f0',
    shadow: 'rgba(0, 0, 0, 0.1)',
    shadowLight: 'rgba(0, 0, 0, 0.05)'
  }
}

export const darkTheme: ThemeConfig = {
  id: 'dark',
  name: '暗色主题',
  icon: '🌙',
  colors: {
    primary: '#4a9eff',
    primaryLight: '#6db3ff',
    primaryDark: '#3a8eef',
    secondary: '#f5a623',
    success: '#7ed321',
    warning: '#f5a623',
    danger: '#ff4757',
    info: '#4a9eff',
    background: '#1a1d23',
    backgroundSecondary: '#22262e',
    surface: '#2a2f38',
    surfaceHover: '#353a45',
    text: '#e8eaed',
    textSecondary: '#b8bbbf',
    textMuted: '#8a8d91',
    border: '#3a3f48',
    borderLight: '#2a2f38',
    shadow: 'rgba(0, 0, 0, 0.3)',
    shadowLight: 'rgba(0, 0, 0, 0.15)'
  }
}

export const colorfulTheme: ThemeConfig = {
  id: 'colorful',
  name: '多彩主题',
  icon: '🌈',
  colors: {
    primary: '#6c5ce7',
    primaryLight: '#a29bfe',
    primaryDark: '#5849c2',
    secondary: '#fd79a8',
    success: '#00b894',
    warning: '#fdcb6e',
    danger: '#e17055',
    info: '#74b9ff',
    background: '#ffeaa7',
    backgroundSecondary: '#fdcb6e',
    surface: '#ffffff',
    surfaceHover: '#f8f9fa',
    text: '#2d3436',
    textSecondary: '#636e72',
    textMuted: '#b2bec3',
    border: '#dfe6e9',
    borderLight: '#ffeaa7',
    shadow: 'rgba(108, 92, 231, 0.2)',
    shadowLight: 'rgba(108, 92, 231, 0.1)'
  }
}

export const themes: ThemeConfig[] = [lightTheme, darkTheme, colorfulTheme]

export function getThemeById(id: string): ThemeConfig | undefined {
  return themes.find(t => t.id === id)
}

export const defaultTheme = lightTheme

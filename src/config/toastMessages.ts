export interface ToastMessages {
  taskAdd: string[]
  taskDelete: string[]
  taskComplete: string[]
  taskMove: string[]
  themeChange: string[]
  reset: string[]
  star: string[]
  unstar: string[]
}

export const toastMessages: ToastMessages = {
  taskAdd: [
    '✨ 新任务已就位！加油完成它！',
    '🎯 任务添加成功！向着目标前进！',
    '🚀 新任务起飞！准备好大展身手了吗？',
    '📝 任务已记录！千里之行始于足下~',
    '💪 新任务添加成功！你可以的！',
    '🌟 任务清单+1！继续保持！'
  ],
  taskDelete: [
    '👋 任务已移除，轻松了一点呢~',
    '🗑️ 任务删除成功！保持简洁很重要',
    '✅ 任务已清除！专注于重要的事吧',
    '🎯 精简成功！质量胜于数量',
    '💨 任务消失在空气中~',
    '🏃 删掉了！轻装上阵！'
  ],
  taskComplete: [
    '🎉 太棒了！任务完成！',
    '🏆 恭喜！又一个成就解锁！',
    '👏 完美！你做得很好！',
    '⭐ 任务完成！你是效率达人！',
    '💪 干得漂亮！继续保持！',
    '🚀 完成任务！冲向下一个目标！'
  ],
  taskMove: [
    '🔄 任务已移动！',
    '📍 位置更新成功！',
    '✨ 重新组织，效率加倍！',
    '🎯 调整布局，专注当前！'
  ],
  themeChange: [
    '🎨 主题切换成功！新风格上线~',
    '✨ 界面焕然一新！',
    '🌈 换个心情，换个主题！',
    '🎭 风格已切换！享受新体验！'
  ],
  reset: [
    '🔄 看板已重置！全新的开始~',
    '✨ 清空完毕！从零开始！',
    '🆕 重新开始！期待新任务！'
  ],
  star: [
    '⭐ 已标记为重要！',
    '🌟 星标添加！重要任务锁定！',
    '✨ 标记成功！优先关注！'
  ],
  unstar: [
    '💫 星标已移除',
    '✨ 取消标记！灵活调整~'
  ]
}

export type ToastType = keyof ToastMessages

export function getRandomMessage(type: ToastType): string {
  const messages = toastMessages[type]
  const index = Math.floor(Math.random() * messages.length)
  return messages[index]
}

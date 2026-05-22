<template>
  <div class="modal-overlay" @click.self="$emit('close')">
    <div class="modal">
      <div class="modal-header">
        <div class="modal-icon">✨</div>
        <h2 class="modal-title">新增任务</h2>
        <button class="close-btn" @click="$emit('close')">×</button>
      </div>
      
      <form @submit.prevent="onSubmit">
        <div class="form-group">
          <div class="floating-label" :class="{ active: form.title }">
            <input 
              v-model="form.title" 
              type="text" 
              placeholder=" "
              required 
              maxlength="100" 
              ref="titleInput"
              class="input-field"
            />
            <label>任务标题 <span class="required">*</span></label>
          </div>
        </div>
        
        <div class="form-group">
          <div class="floating-label textarea-label" :class="{ active: form.description }">
            <textarea 
              v-model="form.description" 
              placeholder=" "
              rows="3" 
              maxlength="500"
              class="input-field textarea"
            ></textarea>
            <label>任务描述</label>
          </div>
        </div>
        
        <div class="form-row">
          <div class="form-group flex-1">
            <div class="floating-label" :class="{ active: form.category }">
              <input 
                v-model="form.category" 
                type="text" 
                placeholder=" "
                maxlength="20"
                list="category-list"
                class="input-field"
              />
              <label>分类标签</label>
              <datalist id="category-list">
                <option v-for="cat in existingCategories" :key="cat" :value="cat"></option>
              </datalist>
            </div>
          </div>
          
          <div class="form-group column-select">
            <label class="select-label">状态列</label>
            <div class="select-wrapper">
              <select v-model="form.columnId" class="select-field">
                <option v-for="col in columns" :key="col.id" :value="col.id">
                  {{ col.title }}
                </option>
              </select>
              <span class="select-arrow">▼</span>
            </div>
          </div>
        </div>
        
        <div class="form-row checkbox-row">
          <label class="checkbox-label starred">
            <input type="checkbox" v-model="form.starred" />
            <span class="checkbox-custom">⭐</span>
            <span class="checkbox-text">星标重要</span>
          </label>
          <label class="checkbox-label urgent">
            <input type="checkbox" v-model="form.urgent" />
            <span class="checkbox-custom">🔥</span>
            <span class="checkbox-text">紧急任务</span>
          </label>
        </div>
        
        <div class="modal-actions">
          <button type="button" class="btn btn-cancel" @click="$emit('close')">
            <span class="btn-text">取消</span>
          </button>
          <button type="submit" class="btn btn-primary">
            <span class="btn-icon">+</span>
            <span class="btn-text">添加任务</span>
          </button>
        </div>
      </form>
    </div>
  </div>
</template>

<script setup>
import { reactive, ref, onMounted } from 'vue'
import { generateId } from '../utils/storage.js'

const props = defineProps({
  columns: { type: Array, required: true },
  existingCategories: { type: Array, default: () => [] }
})

const emit = defineEmits(['close', 'submit'])

const titleInput = ref(null)

const form = reactive({
  title: '',
  description: '',
  category: '',
  columnId: props.columns[0]?.id || 'todo',
  starred: false,
  urgent: false
})

onMounted(() => {
  titleInput.value?.focus()
})

function onSubmit() {
  if (!form.title.trim()) return
  emit('submit', {
    id: generateId(),
    title: form.title.trim(),
    description: form.description.trim(),
    category: form.category.trim(),
    columnId: form.columnId,
    starred: form.starred,
    urgent: form.urgent,
    createdAt: Date.now()
  })
  emit('close')
}
</script>

<style scoped>
.modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.5);
  backdrop-filter: blur(8px);
  -webkit-backdrop-filter: blur(8px);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: var(--z-index-modal);
  animation: fade-in 0.2s ease;
}

@keyframes fade-in {
  from { opacity: 0; }
  to { opacity: 1; }
}

.modal {
  background: var(--color-surface);
  border-radius: var(--radius-xl);
  padding: var(--spacing-xl);
  width: 90%;
  max-width: 520px;
  box-shadow: 
    0 20px 60px rgba(0, 0, 0, 0.3),
    0 0 0 1px rgba(255, 255, 255, 0.1);
  animation: modal-slide-up 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
}

@keyframes modal-slide-up {
  from {
    opacity: 0;
    transform: translateY(30px) scale(0.95);
  }
  to {
    opacity: 1;
    transform: translateY(0) scale(1);
  }
}

.modal-header {
  display: flex;
  align-items: center;
  gap: var(--spacing-md);
  margin-bottom: var(--spacing-xl);
  position: relative;
}

.modal-icon {
  font-size: 28px;
  animation: icon-bounce 0.5s ease 0.2s;
}

@keyframes icon-bounce {
  0%, 100% { transform: scale(1); }
  50% { transform: scale(1.2); }
}

.modal-title {
  margin: 0;
  font-size: var(--font-size-xl);
  color: var(--color-text);
  font-weight: 600;
  flex: 1;
}

.close-btn {
  position: absolute;
  right: 0;
  top: 0;
  width: 32px;
  height: 32px;
  border: none;
  background: var(--color-background-secondary);
  border-radius: var(--radius-full);
  cursor: pointer;
  font-size: 18px;
  color: var(--color-text-muted);
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all var(--transition-fast);
}

.close-btn:hover {
  background: var(--color-danger);
  color: white;
  transform: rotate(90deg);
}

.form-group {
  margin-bottom: var(--spacing-lg);
}

.floating-label {
  position: relative;
}

.floating-label label {
  position: absolute;
  left: var(--spacing-md);
  top: 50%;
  transform: translateY(-50%);
  font-size: var(--font-size-base);
  color: var(--color-text-muted);
  pointer-events: none;
  transition: all var(--transition-fast);
  background: transparent;
  padding: 0 4px;
}

.floating-label.textarea-label label {
  top: 16px;
  transform: none;
}

.floating-label.active label,
.floating-label .input-field:focus + label {
  top: 0;
  transform: translateY(-50%);
  font-size: var(--font-size-xs);
  color: var(--color-primary);
  background: var(--color-surface);
}

.input-field {
  width: 100%;
  padding: var(--spacing-md);
  border: 2px solid var(--color-border);
  border-radius: var(--radius-lg);
  font-size: var(--font-size-md);
  background: var(--color-surface);
  color: var(--color-text);
  outline: none;
  transition: all var(--transition-fast);
  box-sizing: border-box;
}

.input-field:focus {
  border-color: var(--color-primary);
  box-shadow: 0 0 0 4px rgba(74, 158, 255, 0.1);
}

.textarea {
  min-height: 80px;
  resize: vertical;
}

.required {
  color: var(--color-danger);
}

.form-row {
  display: flex;
  gap: var(--spacing-md);
  margin-bottom: var(--spacing-lg);
}

.flex-1 {
  flex: 1;
}

.column-select {
  min-width: 140px;
}

.select-label {
  display: block;
  font-size: var(--font-size-xs);
  font-weight: 500;
  color: var(--color-text-muted);
  margin-bottom: 6px;
}

.select-wrapper {
  position: relative;
}

.select-field {
  width: 100%;
  padding: var(--spacing-md);
  padding-right: 32px;
  border: 2px solid var(--color-border);
  border-radius: var(--radius-lg);
  font-size: var(--font-size-md);
  background: var(--color-surface);
  color: var(--color-text);
  cursor: pointer;
  appearance: none;
  outline: none;
  transition: all var(--transition-fast);
}

.select-field:focus {
  border-color: var(--color-primary);
  box-shadow: 0 0 0 4px rgba(74, 158, 255, 0.1);
}

.select-arrow {
  position: absolute;
  right: 12px;
  top: 50%;
  transform: translateY(-50%);
  font-size: 10px;
  color: var(--color-text-muted);
  pointer-events: none;
}

.checkbox-row {
  background: var(--color-background);
  padding: var(--spacing-md);
  border-radius: var(--radius-lg);
  border: 1px solid var(--color-border-light);
}

.checkbox-label {
  display: flex;
  align-items: center;
  gap: var(--spacing-sm);
  font-size: var(--font-size-sm);
  color: var(--color-text-secondary);
  cursor: pointer;
  padding: var(--spacing-sm) var(--spacing-md);
  border-radius: var(--radius-md);
  transition: all var(--transition-fast);
}

.checkbox-label:hover {
  background: var(--color-surface);
}

.checkbox-label input {
  display: none;
}

.checkbox-custom {
  font-size: 20px;
  filter: grayscale(1) opacity(0.5);
  transition: all var(--transition-fast);
}

.checkbox-label input:checked + .checkbox-custom {
  filter: none;
  transform: scale(1.1);
}

.checkbox-label.starred input:checked ~ .checkbox-text {
  color: var(--color-warning);
}

.checkbox-label.urgent input:checked ~ .checkbox-text {
  color: var(--color-danger);
}

.modal-actions {
  display: flex;
  justify-content: flex-end;
  gap: var(--spacing-md);
  margin-top: var(--spacing-xl);
}

.btn {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: var(--spacing-md) var(--spacing-xl);
  border: none;
  border-radius: var(--radius-lg);
  font-size: var(--font-size-md);
  font-weight: 500;
  cursor: pointer;
  transition: all var(--transition-fast);
  position: relative;
  overflow: hidden;
}

.btn-cancel {
  background: var(--color-background-secondary);
  color: var(--color-text-secondary);
  border: 1px solid var(--color-border);
}

.btn-cancel:hover {
  background: var(--color-border);
  transform: translateY(-1px);
}

.btn-primary {
  background: linear-gradient(135deg, var(--color-primary) 0%, var(--color-primary-dark) 100%);
  color: white;
  box-shadow: 0 4px 12px rgba(74, 158, 255, 0.3);
}

.btn-primary:hover {
  transform: translateY(-2px);
  box-shadow: 0 6px 20px rgba(74, 158, 255, 0.4);
}

.btn-primary:active {
  transform: translateY(0);
}

.btn-icon {
  font-size: 18px;
}
</style>

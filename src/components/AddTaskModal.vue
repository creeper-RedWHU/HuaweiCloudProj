<template>
  <div class="modal-overlay" @click.self="$emit('close')">
    <div class="modal">
      <h2 class="modal-title">新增任务</h2>
      <form @submit.prevent="onSubmit">
        <div class="form-group">
          <label>任务标题 <span class="required">*</span></label>
          <input v-model="form.title" type="text" placeholder="输入任务标题" required maxlength="100" ref="titleInput" />
        </div>
        <div class="form-group">
          <label>描述</label>
          <textarea v-model="form.description" placeholder="输入任务描述（可选）" rows="3" maxlength="500"></textarea>
        </div>
        <div class="form-row">
          <div class="form-group flex-1">
            <label>分类</label>
            <div class="category-input-wrap">
              <input v-model="form.category" type="text" placeholder="如：设计、开发、测试" maxlength="20"
                list="category-list" />
              <datalist id="category-list">
                <option v-for="cat in existingCategories" :key="cat" :value="cat"></option>
              </datalist>
            </div>
          </div>
          <div class="form-group">
            <label>状态列</label>
            <select v-model="form.columnId">
              <option v-for="col in columns" :key="col.id" :value="col.id">{{ col.title }}</option>
            </select>
          </div>
        </div>
        <div class="form-row">
          <label class="checkbox-label">
            <input type="checkbox" v-model="form.starred" />
            <span>星标</span>
          </label>
          <label class="checkbox-label">
            <input type="checkbox" v-model="form.urgent" />
            <span>紧急</span>
          </label>
        </div>
        <div class="modal-actions">
          <button type="button" class="btn btn-cancel" @click="$emit('close')">取消</button>
          <button type="submit" class="btn btn-primary">添加</button>
        </div>
      </form>
    </div>
  </div>
</template>

<script setup>
import { reactive, ref, onMounted, computed } from 'vue'
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
  background: rgba(0, 0, 0, 0.4);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 100;
}

.modal {
  background: #fff;
  border-radius: 12px;
  padding: 24px;
  width: 90%;
  max-width: 480px;
  box-shadow: 0 8px 30px rgba(0, 0, 0, 0.2);
}

.modal-title {
  margin: 0 0 20px;
  font-size: 18px;
  color: #333;
}

.form-group {
  margin-bottom: 14px;
}

.form-group label {
  display: block;
  font-size: 13px;
  font-weight: 500;
  color: #555;
  margin-bottom: 4px;
}

.required {
  color: #d0021b;
}

.form-group input[type="text"],
.form-group textarea,
.form-group select {
  width: 100%;
  padding: 8px 10px;
  border: 1px solid #ddd;
  border-radius: 6px;
  font-size: 14px;
  outline: none;
  transition: border-color 0.15s;
  box-sizing: border-box;
}

.form-group input:focus,
.form-group textarea:focus,
.form-group select:focus {
  border-color: #4a9eff;
}

.form-row {
  display: flex;
  gap: 12px;
  margin-bottom: 14px;
}

.flex-1 {
  flex: 1;
}

.category-input-wrap {
  position: relative;
}

.checkbox-label {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 13px;
  color: #555;
  cursor: pointer;
}

.checkbox-label input {
  accent-color: #4a9eff;
}

.modal-actions {
  display: flex;
  justify-content: flex-end;
  gap: 8px;
  margin-top: 20px;
}

.btn {
  padding: 8px 20px;
  border: none;
  border-radius: 6px;
  font-size: 14px;
  cursor: pointer;
  transition: background 0.15s;
}

.btn-cancel {
  background: #f0f0f0;
  color: #666;
}

.btn-cancel:hover {
  background: #e0e0e0;
}

.btn-primary {
  background: #4a9eff;
  color: #fff;
}

.btn-primary:hover {
  background: #3a8eef;
}
</style>

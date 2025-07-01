<template>
  <div class="forgot-password">
    <el-form
      ref="formRef"
      :model="form"
      :rules="rules"
      label-width="0"
    >
      <el-form-item prop="email">
        <el-input
          v-model="form.email"
          placeholder="请输入邮箱"
          prefix-icon="Message"
        />
      </el-form-item>
      <el-form-item prop="code">
        <el-input
          v-model="form.code"
          placeholder="请输入验证码"
          prefix-icon="Lock"
        >
          <template #append>
            <el-button 
              :disabled="isCountDown" 
              @click="handleSendCode"
            >
              {{ countDownText }}
            </el-button>
          </template>
        </el-input>
      </el-form-item>
      <el-form-item prop="password">
        <el-input
          v-model="form.password"
          type="password"
          placeholder="请输入新密码(6-20个字符)"
          prefix-icon="Lock"
          show-password
        />
      </el-form-item>
      <el-form-item prop="confirmPassword">
        <el-input
          v-model="form.confirmPassword"
          type="password"
          placeholder="请确认新密码"
          prefix-icon="Lock"
          show-password
        />
      </el-form-item>
      <el-button type="primary" :loading="loading" @click="handleReset" round block>
        重置密码
      </el-button>
    </el-form>
    <div class="login-link">
      想起密码了? 
      <el-button link type="primary" @click="$router.push('/login')">
        立即登录
      </el-button>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { Message, Lock } from '@element-plus/icons-vue'
import request from '@/utils/request'

const router = useRouter()
const formRef = ref(null)
const loading = ref(false)
const countDown = ref(0)

// 表单数据
const form = ref({
  email: '',
  code: '',
  password: '',
  confirmPassword: ''
})

// 表单验证规则
const rules = {
  email: [
    { required: true, message: '请输入邮箱', trigger: 'blur' },
    { type: 'email', message: '请输入正确的邮箱格式', trigger: 'blur' },
    { max: 100, message: '邮箱长度不能超过100个字符', trigger: 'blur' }
  ],
  code: [
    { required: true, message: '请输入验证码', trigger: 'blur' },
    { pattern: /^\d{6}$/, message: '验证码必须是6位数字', trigger: 'blur' }
  ],
  password: [
    { required: true, message: '请输入新密码', trigger: 'blur' },
    { min: 6, message: '密码长度不能小于6位', trigger: 'blur' },
    { max: 20, message: '密码长度不能超过20位', trigger: 'blur' },
    { pattern: /^[a-zA-Z0-9_-]+$/, message: '密码只能包含字母、数字、下划线和中划线', trigger: 'blur' }
  ],
  confirmPassword: [
    { required: true, message: '请确认新密码', trigger: 'blur' },
    {
      validator: (rule, value, callback) => {
        if (value !== form.value.password) {
          callback(new Error('两次输入的密码不一致'))
        } else {
          callback()
        }
      },
      trigger: ['blur', 'change']
    }
  ]
}

// 倒计时文本
const countDownText = computed(() => {
  if (countDown.value <= 0) return '获取验证码'
  return `${countDown.value}s后重试`
})

// 是否在倒计时
const isCountDown = computed(() => countDown.value > 0)

// 发送验证码
const handleSendCode = async () => {
  try {
    await formRef.value.validateField('email')
    
    const { data: res } = await request.post('/api/auth/reset/code', {
      email: form.value.email.trim()  // 确保去除空格
    })
    
    if (res.code === 200) {
      ElMessage.success('验证码已发送，请注意查收')
      
      // 开始倒计时
      countDown.value = 60
      const timer = setInterval(() => {
        countDown.value--
        if (countDown.value <= 0) {
          clearInterval(timer)
        }
      }, 1000)
    } else {
      ElMessage.error(res.data || '验证码发送失败')
    }
  } catch (error) {
    ElMessage.error('验证码发送失败，请稍后重试')
  }
}

// 重置密码
const handleReset = async () => {
  if (!formRef.value) return
  
  try {
    await formRef.value.validate()
    loading.value = true
    
    const { data: res } = await request.post('/api/auth/reset/password', {
      email: form.value.email.trim(),  // 确保去除空格
      code: form.value.code,
      password: form.value.password
    })
    
    if (res.code === 200) {
      ElMessage.success('密码重置成功')
      router.push('/login')
    } else {
      ElMessage.error(res.data || '密码重置失败')
    }
  } catch (error) {
    ElMessage.error('密码重置失败，请稍后重试')
  } finally {
    loading.value = false
  }
}
</script>

<style lang="scss" scoped>
.forgot-password {
  .login-link {
    margin-top: 16px;
    text-align: center;
    color: #606266;
  }
}
</style> 
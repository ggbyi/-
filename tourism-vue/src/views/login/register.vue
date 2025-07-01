<template>
  <div class="register">
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
      <el-form-item prop="username">
        <el-input
          v-model="form.username"
          placeholder="请输入用户名(3-50个字符)"
          prefix-icon="User"
        />
      </el-form-item>
      <el-form-item prop="nickname">
        <el-input
          v-model="form.nickname"
          placeholder="请输入昵称(选填)"
          prefix-icon="User"
        />
      </el-form-item>
      <el-form-item prop="password">
        <el-input
          v-model="form.password"
          type="password"
          placeholder="请输入密码(6-20个字符)"
          prefix-icon="Lock"
          show-password
        />
      </el-form-item>
      <el-form-item prop="confirmPassword">
        <el-input
          v-model="form.confirmPassword"
          type="password"
          placeholder="请确认密码"
          prefix-icon="Lock"
          show-password
        />
      </el-form-item>
      <el-form-item prop="gender">
        <el-radio-group v-model="form.gender">
          <el-radio :value="0">保密</el-radio>
          <el-radio :value="1">男</el-radio>
          <el-radio :value="2">女</el-radio>
        </el-radio-group>
      </el-form-item>
      <el-button type="primary" :loading="loading" @click="handleRegister" round block>
        注册
      </el-button>
    </el-form>
    <div class="login-link">
      已有账号? 
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
import { User, Message, Lock } from '@element-plus/icons-vue'
import request from '@/utils/request'

const router = useRouter()
const formRef = ref(null)
const loading = ref(false)
const countDown = ref(0)

const form = ref({
  email: '',
  code: '',
  username: '',
  nickname: '',
  password: '',
  confirmPassword: '',
  gender: 0
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
  username: [
    { required: true, message: '请输入用户名', trigger: 'blur' },
    { min: 3, message: '用户名长度不能小于3位', trigger: 'blur' },
    { max: 50, message: '用户名长度不能超过50个字符', trigger: 'blur' },
    { pattern: /^[a-zA-Z0-9_-]+$/, message: '用户名只能包含字母、数字、下划线和中划线', trigger: 'blur' }
  ],
  nickname: [
    { max: 50, message: '昵称长度不能超过50个字符', trigger: 'blur' }
  ],
  password: [
    { required: true, message: '请输入密码', trigger: 'blur' },
    { min: 6, message: '密码长度不能小于6位', trigger: 'blur' },
    { max: 20, message: '密码长度不能超过20位', trigger: 'blur' },
    { pattern: /^[a-zA-Z0-9_-]+$/, message: '密码只能包含字母、数字、下划线和中划线', trigger: 'blur' }
  ],
  confirmPassword: [
    { required: true, message: '请确认密码', trigger: 'blur' },
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
    
    const { data: res } = await request.post('/api/auth/register/code', {
      email: form.value.email
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
      console.log()
      ElMessage.error(res.data || '验证码发送失败')
    }
  } catch (error) {
    ElMessage.error('验证码发送失败，请稍后重试')
  }
}

// 注册
const handleRegister = async () => {
  if (!formRef.value) return
  
  try {
    await formRef.value.validate()
    loading.value = true
    
    const { data: res } = await request.post('/api/auth/register', {
      email: form.value.email,
      code: form.value.code,
      username: form.value.username,
      nickname: form.value.nickname || form.value.username,
      password: form.value.password,
      gender: form.value.gender
    })
    
    if (res.code === 200) {
      ElMessage.success('注册成功')
      router.push('/')
    } else {
      ElMessage.error(res.data || '注册失败')
    }
  } catch (error) {
    if (error.response && error.response.status === 409) {
      ElMessage.error('邮箱已被注册')
    } else {
      ElMessage.error('注册失败，请稍后重试')
    }
  } finally {
    loading.value = false
  }
}
</script>

<style lang="scss" scoped>
.register {
  .login-link {
    margin-top: 16px;
    text-align: center;
    color: #606266;
  }
}
</style> 
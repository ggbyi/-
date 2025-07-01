<template>
  <div class="login-container">
    <div class="login-box">
      <div class="login-header">
        <h2>旅游景点推荐系统</h2>
        <p>欢迎回来，请登录您的账号</p>
      </div>
      
      <el-form :model="loginForm" :rules="loginRules" ref="loginFormRef" class="login-form">
        <!-- 用户类型选择 -->
        <div class="user-type-selector">
          <div 
            :class="['type-item', { active: loginForm.userType === 'user' }]" 
            @click="loginForm.userType = 'user'"
          >
            <el-icon><User /></el-icon>
            <span>普通用户</span>
          </div>
          <div 
            :class="['type-item', { active: loginForm.userType === 'admin' }]" 
            @click="loginForm.userType = 'admin'"
          >
            <el-icon><Setting /></el-icon>
            <span>管理员</span>
          </div>
        </div>
        
        <!-- 用户名输入框 -->
        <el-form-item prop="username">
          <el-input 
            v-model="loginForm.username" 
            placeholder="请输入用户名"
            prefix-icon="User"
          />
        </el-form-item>
        
        <!-- 密码输入框 -->
        <el-form-item prop="password">
          <el-input 
            v-model="loginForm.password" 
            type="password" 
            placeholder="请输入密码"
            prefix-icon="Lock"
            show-password
          />
        </el-form-item>
        
        <!-- 记住我 & 忘记密码 -->
        <div class="form-options">
          <el-checkbox v-model="loginForm.remember">记住我</el-checkbox>
          <el-button type="text" @click="goToReset">忘记密码?</el-button>
        </div>
        
        <!-- 登录按钮 -->
        <el-form-item>
          <el-button 
            type="primary" 
            class="login-button" 
            :loading="loading" 
            @click="handleLogin"
          >
            登录
          </el-button>
        </el-form-item>
        
        <!-- 注册链接 -->
        <div class="register-link">
          还没有账号? <el-button type="text" @click="goToRegister">立即注册</el-button>
        </div>
      </el-form>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { User, Lock, Setting } from '@element-plus/icons-vue'
import request from '@/utils/request'
import { useUserStore } from '@/stores/user'

const router = useRouter()
const userStore = useUserStore()
const loginFormRef = ref(null)
const loading = ref(false)

// 登录表单数据
const loginForm = reactive({
  username: '',
  password: '',
  remember: false,
  userType: 'user' // 默认为普通用户
})

// 表单验证规则
const loginRules = {
  username: [
    { required: true, message: '请输入用户名', trigger: 'blur' },
    { min: 3, max: 20, message: '用户名长度应为3-20个字符', trigger: 'blur' }
  ],
  password: [
    { required: true, message: '请输入密码', trigger: 'blur' },
    { min: 6, max: 20, message: '密码长度应为6-20个字符', trigger: 'blur' }
  ]
}

// 处理登录
const handleLogin = async () => {
  try {
    // 表单验证
    await loginFormRef.value.validate()
    
    loading.value = true
    
    // 发送登录请求
    const { data: res } = await request.post('/api/auth/login', {
      username: loginForm.username,
      password: loginForm.password,
      userType: loginForm.userType
    })
    
    if (res.code === 200) {
      // 登录成功，保存用户信息和token
      const userData = {
        ...res.data,
        role: res.data.role
      }
      
      // 存储token到localStorage
      localStorage.setItem('token', res.data.token)
      localStorage.setItem('userRole', res.data.role)
      
      // 更新用户信息到store
      userStore.setUserInfo(userData)
      userStore.setRole(res.data.role)
      
      // 根据用户类型跳转到不同页面
      if (res.data.role === 'ROLE_ADMIN') {
        router.push('/admin/users')
      } else {
        router.push('/user/explore')
      }
      
      ElMessage.success('登录成功')
    } else {
      ElMessage.error(res.msg || '登录失败')
    }
  } catch (error) {
    console.error('登录失败:', error)
    ElMessage.error('登录失败，请检查用户名和密码')
  } finally {
    loading.value = false
  }
}

// 跳转到注册页面
const goToRegister = () => {
  router.push('/register')
}

// 跳转到重置密码页面
const goToReset = () => {
  router.push('/reset')
}
</script>

<style lang="scss" scoped>
.login-container {
  display: flex;
  justify-content: center;
  align-items: center;
  height: 100vh;
  background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
  
  .login-box {
    width: 400px;
    padding: 40px;
    background: #fff;
    border-radius: 10px;
    box-shadow: 0 15px 30px rgba(0, 0, 0, 0.1);
    
    .login-header {
      text-align: center;
      margin-bottom: 30px;
      
      h2 {
        font-size: 24px;
        color: #333;
        margin-bottom: 10px;
      }
      
      p {
        font-size: 14px;
        color: #666;
      }
    }
    
    .user-type-selector {
      display: flex;
      justify-content: space-between;
      margin-bottom: 20px;
      
      .type-item {
        flex: 1;
        display: flex;
        flex-direction: column;
        align-items: center;
        padding: 15px 0;
        border-radius: 8px;
        cursor: pointer;
        transition: all 0.3s;
        margin: 0 5px;
        border: 1px solid #ebeef5;
        
        .el-icon {
          font-size: 24px;
          margin-bottom: 8px;
          color: #909399;
        }
        
        span {
          font-size: 14px;
          color: #606266;
        }
        
        &.active {
          background: #ecf5ff;
          border-color: #409eff;
          
          .el-icon, span {
            color: #409eff;
          }
        }
        
        &:hover {
          transform: translateY(-2px);
          box-shadow: 0 2px 12px 0 rgba(0, 0, 0, 0.1);
        }
      }
    }
    
    .login-form {
      .form-options {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 20px;
      }
      
      .login-button {
        width: 100%;
        padding: 12px 0;
        font-size: 16px;
      }
      
      .register-link {
        text-align: center;
        margin-top: 15px;
        font-size: 14px;
        color: #606266;
      }
    }
  }
}
</style> 
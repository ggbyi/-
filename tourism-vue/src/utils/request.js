import axios from 'axios'
import { ElMessage } from 'element-plus'
import router from '@/router'
import { useUserStore } from '@/stores/user'

// 创建axios实例
const request = axios.create({
  baseURL: 'http://localhost:8080',
  timeout: 30000,
  withCredentials: true
})

// 请求拦截器 - 添加token到请求头
request.interceptors.request.use(
  config => {
    // 从localStorage获取token
    const token = localStorage.getItem('token')
    // 如果token存在，添加到请求头
    if (token) {
      config.headers['Authorization'] = `Bearer ${token}`
    }
    return config
  },
  error => {
    console.error('请求错误:', error)
    return Promise.reject(error)
  }
)

// 响应拦截器 - 处理错误响应
request.interceptors.response.use(
  response => {
    // 请求成功处理
    return response
  },
  error => {
    // 处理401未授权错误（token无效或已过期）
    if (error.response && error.response.status === 401) {
      ElMessage.error('登录已过期，请重新登录')
      
      // 清除用户信息和token
      const userStore = useUserStore()
      userStore.clearUserState()
      
      // 重定向到登录页
      router.push('/login')
    } else {
      // 处理其他错误
      ElMessage.error(error.response?.data?.msg || '请求失败')
    }
    
    return Promise.reject(error)
  }
)

export default request 
import { defineStore } from 'pinia'
import request from '@/utils/request'

export const useUserStore = defineStore('user', {
  state: () => ({
    userInfo: null,
    role: ''
  }),

  getters: {
    isLoggedIn: (state) => !!state.userInfo,
    isAdmin: (state) => state.role === 'ADMIN'
  },

  actions: {
    setUserInfo(userInfo) {
      this.userInfo = userInfo
    },

    setRole(role) {
      this.role = role
    },

    clearUserInfo() {
      this.userInfo = null
      this.role = ''
      localStorage.removeItem('token')
      localStorage.removeItem('userRole')
    },

    // 登录
    async login(loginData) {
      try {
        const res = await request.post('/api/auth/login', loginData)
        if (res.data.code === 200) {
          this.setUserInfo(res.data.data.user)
          this.setRole(res.data.data.role)
          localStorage.setItem('token', res.data.data.token)
          localStorage.setItem('userRole', res.data.data.role)
        }
        return res.data
      } catch (error) {
        throw error
      }
    },

    // 退出登录
    async logout() {
      try {
        await request.post('/api/auth/logout')
        this.clearUserInfo()
      } catch (error) {
        throw error
      }
    },

    // 获取用户信息
    async getUserInfo() {
      try {
        const res = await request({
          url: '/api/user/info',
          method: 'get'
        })
        this.userInfo = res.data
        return res.data
      } catch (error) {
        throw error
      }
    },

    // 更新用户信息
    updateUserInfo(data) {
      this.userInfo = { ...this.userInfo, ...data }
    },

    // 清除用户状态
    clearUserState() {
      this.userInfo = null
      this.role = ''
      localStorage.removeItem('token')
      localStorage.removeItem('userRole')
    }
  }
}) 
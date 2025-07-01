<template>
  <div class="profile-container">
    <el-card>
      <div class="profile-header">
        <h2>个人信息</h2>
      </div>

      <el-tabs v-model="activeTab">
        <!-- 基本信息 -->
        <el-tab-pane label="基本信息" name="info">
          <el-form ref="infoForm" :model="userInfo" :rules="rules" label-width="100px">
            <el-form-item label="用户ID">
              <el-input v-model="userInfo.userId" disabled />
            </el-form-item>

            <el-form-item label="昵称" prop="nickname">
              <el-input v-model="userInfo.nickname" />
            </el-form-item>

            <el-form-item label="性别" prop="gender">
              <el-radio-group v-model="userInfo.gender">
                <el-radio :label="1">男</el-radio>
                <el-radio :label="2">女</el-radio>
                <el-radio :label="0">保密</el-radio>
              </el-radio-group>
            </el-form-item>

            <el-form-item label="手机号" prop="phone">
              <el-input v-model="userInfo.phone" maxlength="11" />
            </el-form-item>

            <el-form-item label="邮箱">
              <el-input v-model="userInfo.email" disabled />
            </el-form-item>

            <el-form-item>
              <el-button type="primary" @click="submitInfo">保存修改</el-button>
            </el-form-item>
          </el-form>
        </el-tab-pane>

        <!-- 修改密码 -->
        <el-tab-pane label="修改密码" name="password">
          <el-form ref="pwdFormRef" :model="pwdForm" :rules="pwdRules" label-width="100px">
            <el-form-item label="原密码" prop="oldPassword">
              <el-input 
                v-model="pwdForm.oldPassword" 
                type="password" 
                show-password
                placeholder="请输入原密码"
              />
            </el-form-item>

            <el-form-item label="新密码" prop="newPassword">
              <el-input
                v-model="pwdForm.newPassword"
                type="password"
                show-password
                placeholder="请输入新密码"
              />
            </el-form-item>

            <el-form-item label="确认密码" prop="confirmPassword">
              <el-input
                v-model="pwdForm.confirmPassword"
                type="password"
                show-password
                placeholder="请再次输入新密码"
              />
            </el-form-item>

            <el-form-item>
              <el-button type="primary" @click="submitPassword">修改密码</el-button>
            </el-form-item>
          </el-form>
        </el-tab-pane>
      </el-tabs>
    </el-card>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import request from '@/utils/request'
import { useUserStore } from '@/stores/user'

const userStore = useUserStore()
const activeTab = ref('info')
const pwdFormRef = ref(null)

// 用户信息相关
const userInfo = ref({
  userId: '',
  nickname: '',
  gender: 0,
  phone: '',
  email: ''
})

const rules = reactive({
  nickname: [
    { required: true, message: '请输入昵称', trigger: 'blur' },
    { min: 2, max: 20, message: '长度在2到20个字符', trigger: 'blur' }
  ],
  phone: [
    { pattern: /^1[3-9]\d{9}$/, message: '请输入正确的手机号', trigger: 'blur' }
  ]
})

// 密码相关
const pwdForm = reactive({
  oldPassword: '',
  newPassword: '',
  confirmPassword: ''
})

const pwdRules = reactive({
  oldPassword: [
    { required: true, message: '请输入原密码', trigger: 'blur' }
  ],
  newPassword: [
    { required: true, message: '请输入新密码', trigger: 'blur' },
    { min: 6, max: 20, message: '长度在6到20个字符', trigger: 'blur' }
  ],
  confirmPassword: [
    { required: true, message: '请再次输入新密码', trigger: 'blur' },
    { validator: validateConfirmPassword, trigger: 'blur' }
  ]
})

// 初始化加载用户信息
onMounted(async () => {
  await loadUserInfo()
})

// 加载用户信息
const loadUserInfo = async () => {
  try {
    const { data: res } = await request.get('/api/user/info')
    if (res.code === 200) {
      userInfo.value = {
        userId: res.data.userId,
        nickname: res.data.nickname,
        gender: res.data.gender || 0,
        phone: res.data.phone || '',
        email: res.data.email
      }
    }
  } catch (error) {
    ElMessage.error('获取用户信息失败')
  }
}

// 提交基本信息修改
const submitInfo = async () => {
  try {
    const params = {
      nickname: userInfo.value.nickname,
      gender: userInfo.value.gender,
      phone: userInfo.value.phone
    }
    const { data: res } = await request.put('/api/user/profile', params)
    if (res.code === 200) {
      userStore.updateUserInfo(params)
      ElMessage.success('信息更新成功')
    }
  } catch (error) {
    ElMessage.error(error.response?.data?.msg || '信息更新失败')
  }
}

// 密码校验规则
function validateConfirmPassword(rule, value, callback) {
  if (value !== pwdForm.newPassword) {
    callback(new Error('两次输入密码不一致!'))
  } else {
    callback()
  }
}

// 提交密码修改
const submitPassword = async () => {
  try {
    await pwdFormRef.value.validate()
    
    const { data: res } = await request.put('/api/user/pwd', {
      oldPassword: pwdForm.oldPassword,
      newPassword: pwdForm.newPassword
    })
    
    if (res.code === 200) {
      ElMessage.success('密码修改成功')
      pwdForm.oldPassword = ''
      pwdForm.newPassword = ''
      pwdForm.confirmPassword = ''
    }
  } catch (error) {
    if (!error.response) return
    ElMessage.error(error.response?.data?.msg || '密码修改失败')
  }
}
</script>

<style lang="scss" scoped>
.profile-container {
  padding: 20px;

  .profile-header {
    margin-bottom: 20px;
    text-align: center;
  }

  :deep(.el-tabs) {
    max-width: 600px;
    margin: 0 auto;
  }

  .el-form {
    margin-top: 20px;
  }
}
</style> 
<template>
  <div class="settings-container">
    <el-card class="settings-card">
      <template #header>
        <div class="card-header">
          <h2>账号设置</h2>
        </div>
      </template>
      
      <!-- 设置导航 -->
      <el-tabs v-model="activeTab">
        <el-tab-pane label="基本信息" name="basic">
          <el-form 
            ref="basicFormRef"
            :model="basicForm" 
            :rules="basicRules"
            label-width="100px"
          >
            <el-form-item label="用户ID">
              <el-input v-model="userInfo.userId" disabled />
            </el-form-item>

            <el-form-item label="昵称" prop="nickname">
              <el-input v-model="basicForm.nickname" maxlength="20" show-word-limit />
            </el-form-item>
            
            <el-form-item label="性别" prop="gender">
              <el-radio-group v-model="basicForm.gender">
                <el-radio :label="1">男</el-radio>
                <el-radio :label="2">女</el-radio>
                <el-radio :label="0">保密</el-radio>
              </el-radio-group>
            </el-form-item>

            <el-form-item label="手机号" prop="phone">
              <el-input v-model="basicForm.phone" maxlength="11" />
            </el-form-item>
            
            <el-form-item label="邮箱">
              <el-input v-model="userInfo.email" disabled />
            </el-form-item>
            
            <el-form-item>
              <el-button type="primary" @click="updateBasicInfo" :loading="loading">
                保存修改
              </el-button>
            </el-form-item>
          </el-form>
        </el-tab-pane>

        <el-tab-pane label="账号安全" name="security">
          <el-form 
            ref="passwordFormRef"
            :model="passwordForm" 
            :rules="passwordRules"
            label-width="100px"
          >
            <el-form-item label="原密码" prop="oldPassword">
              <el-input 
                v-model="passwordForm.oldPassword" 
                type="password" 
                show-password
                placeholder="请输入原密码"
              />
            </el-form-item>
            
            <el-form-item label="新密码" prop="newPassword">
              <el-input 
                v-model="passwordForm.newPassword" 
                type="password" 
                show-password
                placeholder="请输入新密码"
              />
            </el-form-item>
            
            <el-form-item label="确认密码" prop="confirmPassword">
              <el-input 
                v-model="passwordForm.confirmPassword" 
                type="password" 
                show-password
                placeholder="请再次输入新密码"
              />
            </el-form-item>
            
            <el-form-item>
              <el-button type="primary" @click="updatePassword" :loading="loading">
                修改密码
              </el-button>
            </el-form-item>
          </el-form>
        </el-tab-pane>

        <el-tab-pane label="偏好设置" name="preferences">
          <el-form 
            ref="preferencesFormRef"
            :model="preferencesForm"
            label-width="100px"
          >
            <el-form-item label="景点类型">
              <el-checkbox-group v-model="preferencesForm.spotTypes">
                <el-checkbox label="natural">自然风光</el-checkbox>
                <el-checkbox label="cultural">人文古迹</el-checkbox>
                <el-checkbox label="entertainment">游乐设施</el-checkbox>
                <el-checkbox label="shopping">购物中心</el-checkbox>
                <el-checkbox label="food">美食街区</el-checkbox>
              </el-checkbox-group>
            </el-form-item>
            
            <el-form-item label="价格区间">
              <el-select v-model="preferencesForm.priceRange">
                <el-option label="100元以下" value="0-100" />
                <el-option label="100-300元" value="100-300" />
                <el-option label="300-500元" value="300-500" />
                <el-option label="500元以上" value="500+" />
                <el-option label="不限" value="any" />
              </el-select>
            </el-form-item>
            
            <el-form-item label="出行方式">
              <el-radio-group v-model="preferencesForm.travelMode">
                <el-radio label="self">自由行</el-radio>
                <el-radio label="group">跟团游</el-radio>
                <el-radio label="both">都可以</el-radio>
              </el-radio-group>
            </el-form-item>
            
            <el-form-item>
              <el-button type="primary" @click="updatePreferences">保存偏好</el-button>
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
const loading = ref(false)
const activeTab = ref('basic')
const basicFormRef = ref(null)
const passwordFormRef = ref(null)
const preferencesFormRef = ref(null)

// 用户信息
const userInfo = reactive({
  userId: '',
  nickname: '',
  gender: '',
  phone: '',
  email: ''
})

// 基本信息表单
const basicForm = reactive({
  nickname: '',
  gender: 0,
  phone: ''
})

// 密码表单
const passwordForm = reactive({
  oldPassword: '',
  newPassword: '',
  confirmPassword: ''
})

// 偏好设置表单
const preferencesForm = reactive({
  spotTypes: [],
  priceRange: 'any',
  travelMode: 'both'
})

// 验证规则
const basicRules = {
  nickname: [
    { required: true, message: '请输入昵称', trigger: 'blur' },
    { min: 2, max: 20, message: '长度在2到20个字符', trigger: 'blur' }
  ],
  phone: [
    { pattern: /^1[3-9]\d{9}$/, message: '请输入正确的手机号', trigger: 'blur' }
  ]
}

const passwordRules = {
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
}

// 加载用户信息
const loadUserInfo = async () => {
  try {
    const { data: res } = await request.get('/api/user/info')
    if (res.code === 200) {
      userInfo.userId = res.data.userId
      userInfo.email = res.data.email
      basicForm.nickname = res.data.nickname
      basicForm.gender = res.data.gender || 0
      basicForm.phone = res.data.phone || ''
    }
  } catch (error) {
    ElMessage.error('获取用户信息失败')
  }
}

// 更新基本信息
const updateBasicInfo = async () => {
  try {
    await basicFormRef.value.validate()
    const params = {
      nickname: basicForm.nickname,
      gender: basicForm.gender,
      phone: basicForm.phone
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

// 更新密码
const updatePassword = async () => {
  try {
    await passwordFormRef.value.validate()
    const { data: res } = await request.put('/api/user/pwd', {
      oldPassword: passwordForm.oldPassword,
      newPassword: passwordForm.newPassword
    })
    if (res.code === 200) {
      ElMessage.success('密码修改成功')
      passwordForm.oldPassword = ''
      passwordForm.newPassword = ''
      passwordForm.confirmPassword = ''
    }
  } catch (error) {
    if (!error.response) return
    ElMessage.error(error.response?.data?.msg || '密码修改失败')
  }
}

// 密码确认校验
function validateConfirmPassword(rule, value, callback) {
  if (value !== passwordForm.newPassword) {
    callback(new Error('两次输入密码不一致!'))
  } else {
    callback()
  }
}

// 加载偏好设置
const loadPreferences = async () => {
  try {
    loading.value = true;
    const { data: res } = await request.get('/api/user/preferences')
    if (res.code === 200) {
      preferencesForm.spotTypes = res.data.spotTypes || []
      preferencesForm.priceRange = res.data.priceRange || 'any'
      preferencesForm.travelMode = res.data.travelMode || 'both'
    }
  } catch (error) {
    ElMessage.error('获取偏好设置失败')
  } finally {
    loading.value = false;
  }
}

// 更新偏好设置
const updatePreferences = async () => {
  try {
    loading.value = true;
    const { data: res } = await request.put('/api/user/preferences', preferencesForm)
    if (res.code === 200) {
      ElMessage.success('偏好设置已保存')
    }
  } catch (error) {
    ElMessage.error(error.response?.data?.msg || '保存偏好设置失败')
  } finally {
    loading.value = false;
  }
}

onMounted(() => {
  loadUserInfo()
  loadPreferences()
})
</script>

<style lang="scss" scoped>
.settings-container {
  max-width: 800px;
  margin: 0 auto;
  padding: 20px;

  .settings-card {
    .card-header {
      h2 {
        margin: 0;
        font-size: 20px;
        color: #303133;
      }
    }
  }
}

.avatar-uploader {
  :deep(.el-upload) {
    border: 1px dashed #d9d9d9;
    border-radius: 6px;
    cursor: pointer;
    position: relative;
    overflow: hidden;
    transition: var(--el-transition-duration-fast);

    &:hover {
      border-color: var(--el-color-primary);
    }
  }

  .avatar-uploader-icon {
    font-size: 28px;
    color: #8c939d;
    width: 178px;
    height: 178px;
    text-align: center;
    line-height: 178px;
  }

  .avatar {
    width: 178px;
    height: 178px;
    display: block;
    object-fit: cover;
  }
}
</style> 
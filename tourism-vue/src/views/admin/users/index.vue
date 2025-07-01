<template>
  <div class="users-container">
    <!-- 搜索栏 -->
    <div class="search-bar">
      <el-form :inline="true" :model="searchForm">
        <el-form-item>
          <el-input
              v-model="searchForm.keyword"
              placeholder="用户名/邮箱/手机号"
              clearable
              @keyup.enter="handleSearch"
          />
        </el-form-item>

        <el-form-item>
          <el-button type="primary" @click="handleSearch">搜索</el-button>
          <el-button @click="resetSearch">重置</el-button>
          <el-button type="success" @click="openAddUserDialog">新增用户</el-button>
        </el-form-item>
      </el-form>
    </div>

    <!-- 用户列表 -->
    <el-card>
      <el-table
          v-loading="loading"
          :data="userList"
          style="width: 100%"
      >
        <el-table-column label="用户信息" min-width="200">
          <template #default="{ row }">
            <div class="user-info">
              <el-avatar :size="40" :src="row.avatar">
                {{ row.nickname?.charAt(0)?.toUpperCase() || row.username?.charAt(0)?.toUpperCase() }}
              </el-avatar>
              <div class="info">
                <div class="name">{{ row.nickname || row.username }}</div>
                <div class="email">{{ row.email }}</div>
              </div>
            </div>
          </template>
        </el-table-column>

        <el-table-column prop="phone" label="手机号" width="120" />

        <el-table-column label="角色" width="150">
          <template #default="{ row }">
            <el-tag
                v-for="role in row.roles"
                :key="role"
                :type="getRoleType(role)"
                size="small"
                class="mr-1"
            >
              {{ getRoleLabel(role) }}
            </el-tag>
          </template>
        </el-table-column>

        <el-table-column label="状态" width="100">
          <template #default="{ row }">
            <el-switch
                v-model="row.status"
                :active-value="1"
                :inactive-value="0"
                @change="(val) => handleStatusChange(row, val)"
            />
          </template>
        </el-table-column>

        <el-table-column prop="createdTime" label="注册时间" width="160" />

        <el-table-column prop="lastLoginTime" label="最后登录" width="160" />

        <el-table-column label="操作" width="200" fixed="right">
          <template #default="{ row }">
            <el-button-group>
              <el-button
                  type="success"
                  size="small"
                  @click="handleEdit(row)"
              >
                编辑
              </el-button>
              <el-button
                  type="primary"
                  size="small"
                  @click="handleResetPassword(row)"
              >
                重置密码
              </el-button>
              <el-button
                  type="danger"
                  size="small"
                  @click="handleDelete(row)"
              >
                删除
              </el-button>
            </el-button-group>
          </template>
        </el-table-column>
      </el-table>

      <!-- 分页 -->
      <div class="pagination">
        <el-pagination
            background
            :current-page="page"
            :page-size="size"
            :total="total"
            :page-sizes="[10, 20, 50, 100]"
            layout="total, sizes, prev, pager, next"
            @size-change="handleSizeChange"
            @current-change="handleCurrentChange"
        />
      </div>
    </el-card>

    <!-- 添加用户对话框 -->
    <el-dialog
      title="添加新用户"
      v-model="addUserDialogVisible"
      width="500px"
      @close="resetAddUserForm"
    >
      <el-form
        :model="addUserForm"
        :rules="addUserRules"
        ref="addUserFormRef"
        label-width="100px"
      >
        <el-form-item label="用户名" prop="username">
          <el-input v-model="addUserForm.username" placeholder="请输入用户名"></el-input>
        </el-form-item>
        
        <el-form-item label="密码" prop="password">
          <el-input v-model="addUserForm.password" type="password" placeholder="请输入密码" show-password></el-input>
        </el-form-item>
        
        <el-form-item label="邮箱" prop="email">
          <el-input v-model="addUserForm.email" placeholder="请输入邮箱"></el-input>
        </el-form-item>
        
        <el-form-item label="昵称" prop="nickname">
          <el-input v-model="addUserForm.nickname" placeholder="请输入昵称"></el-input>
        </el-form-item>
        
        <el-form-item label="手机号" prop="phone">
          <el-input v-model="addUserForm.phone" placeholder="请输入手机号"></el-input>
        </el-form-item>
        
        <el-form-item label="性别" prop="gender">
          <el-radio-group v-model="addUserForm.gender">
            <el-radio :label="1">男</el-radio>
            <el-radio :label="0">女</el-radio>
            <el-radio :label="2">未知</el-radio>
          </el-radio-group>
        </el-form-item>
        
        <el-form-item label="用户角色" prop="role">
          <el-select v-model="addUserForm.role" placeholder="请选择用户角色">
            <el-option label="普通用户" value="2"></el-option>
            <el-option label="管理员" value="1"></el-option>
          </el-select>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="addUserDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="submitAddUser" :loading="addUserLoading">确定</el-button>
      </template>
    </el-dialog>

    <!-- 编辑用户对话框 -->
    <el-dialog
      title="编辑用户"
      v-model="editUserDialogVisible"
      width="500px"
      @close="resetEditUserForm"
    >
      <el-form
        :model="editUserForm"
        :rules="editUserRules"
        ref="editUserFormRef"
        label-width="100px"
      >
        <el-form-item label="用户名" prop="username">
          <el-input v-model="editUserForm.username" placeholder="请输入用户名"></el-input>
        </el-form-item>
        
        <el-form-item label="密码" prop="password">
          <el-input v-model="editUserForm.password" type="password" placeholder="留空表示不修改密码" show-password></el-input>
        </el-form-item>
        
        <el-form-item label="邮箱" prop="email">
          <el-input v-model="editUserForm.email" placeholder="请输入邮箱"></el-input>
        </el-form-item>
        
        <el-form-item label="昵称" prop="nickname">
          <el-input v-model="editUserForm.nickname" placeholder="请输入昵称"></el-input>
        </el-form-item>
        
        <el-form-item label="手机号" prop="phone">
          <el-input v-model="editUserForm.phone" placeholder="请输入手机号"></el-input>
        </el-form-item>
        
        <el-form-item label="性别" prop="gender">
          <el-radio-group v-model="editUserForm.gender">
            <el-radio :label="1">男</el-radio>
            <el-radio :label="0">女</el-radio>
            <el-radio :label="2">未知</el-radio>
          </el-radio-group>
        </el-form-item>
        
        <el-form-item label="用户角色" prop="roleId">
          <el-select v-model="editUserForm.roleId" placeholder="请选择用户角色">
            <el-option label="普通用户" value="2"></el-option>
            <el-option label="管理员" value="1"></el-option>
          </el-select>
        </el-form-item>

        <el-form-item label="状态" prop="status">
          <el-radio-group v-model="editUserForm.status">
            <el-radio :label="1">启用</el-radio>
            <el-radio :label="0">禁用</el-radio>
          </el-radio-group>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="editUserDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="submitEditUser" :loading="editUserLoading">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, onMounted, reactive } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import request from '@/utils/request'

// 数据列表
const loading = ref(false)
const userList = ref([])
const page = ref(1)
const size = ref(10)
const total = ref(0)

// 搜索表单
const searchForm = ref({
  keyword: '',
  role: '',
  status: ''
})

// 添加用户相关数据
const addUserDialogVisible = ref(false)
const addUserFormRef = ref(null)
const addUserLoading = ref(false)
const addUserForm = reactive({
  username: '',
  password: '',
  email: '',
  nickname: '',
  phone: '',
  gender: 2, // 默认未知
  role: '2', // 默认普通用户
  status: 1   // 默认启用
})

// 添加用户表单验证规则
const addUserRules = {
  username: [
    { required: true, message: '请输入用户名', trigger: 'blur' },
    { min: 3, max: 20, message: '用户名长度应为3-20个字符', trigger: 'blur' }
  ],
  password: [
    { required: true, message: '请输入密码', trigger: 'blur' },
    { min: 6, max: 20, message: '密码长度应为6-20个字符', trigger: 'blur' }
  ],
  email: [
    { required: true, message: '请输入邮箱', trigger: 'blur' },
    { type: 'email', message: '请输入正确的邮箱格式', trigger: 'blur' }
  ],
  nickname: [
    { required: true, message: '请输入昵称', trigger: 'blur' },
    { min: 2, max: 20, message: '昵称长度应为2-20个字符', trigger: 'blur' }
  ],
  phone: [
    { pattern: /^1[3-9]\d{9}$/, message: '请输入正确的手机号码', trigger: 'blur' }
  ],
  role: [
    { required: true, message: '请选择用户角色', trigger: 'change' }
  ]
}

// 获取用户列表
const fetchUsers = async () => {
  loading.value = true
  try {
    const res = await request.get('/api/user/list', {
      params: {
        page: page.value,
        size: size.value,
        ...searchForm.value
      }
    })
    if (res.data.code === 200 && res.data) {
      userList.value = res.data.data.records
      total.value = res.data.total
    } else {
      ElMessage.error(res.data.msg || '获取用户列表失败')
    }
  } catch (error) {
    console.error('获取用户列表失败:', error)
    ElMessage.error('获取用户列表失败')
  } finally {
    loading.value = false
  }
}

// 角色处理
const getRoleType = (role) => {
  switch (role) {
    case 'ROLE_ADMIN':
      return 'danger'
    case 'ROLE_VIP':
      return 'warning'
    default:
      return 'info'
  }
}

const getRoleLabel = (role) => {
  switch (role) {
    case 'ROLE_ADMIN':
      return '管理员'
    case 'ROLE_VIP':
      return 'VIP用户'
    case 'ROLE_USER':
      return '普通用户'
    default:
      return role
  }
}

// 搜索和重置
const handleSearch = () => {
  page.value = 1
  fetchUsers()
}

const resetSearch = () => {
  searchForm.value = {
    keyword: '',
    role: '',
    status: ''
  }
  handleSearch()
}

// 状态修改
const handleStatusChange = async (row, status) => {
  try {
    const res = await request.put(`/api/user/${row.id}/status`, null, {
      params: { status: status === 1 ? 'ACTIVE' : 'DISABLED' }
    })
    if (res.data.code === 200) {
      ElMessage.success('更新状态成功')
    } else {
      row.status = status === 1 ? 0 : 1 // 恢复状态
      ElMessage.error(res.data.msg || '更新状态失败')
    }
  } catch (error) {
    row.status = status === 1 ? 0 : 1 // 恢复状态
    ElMessage.error('更新状态失败')
  }
}

// 分页处理
const handleSizeChange = (val) => {
  size.value = val
  page.value = 1
  fetchUsers()
}

const handleCurrentChange = (val) => {
  page.value = val
  fetchUsers()
}

// 重置密码
const handleResetPassword = async (row) => {
  try {
    await ElMessageBox.confirm('确定要重置该用户的密码吗？')
    const res = await request.put(`/api/user/${row.id}/reset-password`)
    if (res.data.code === 200) {
      ElMessage.success('密码重置成功')
    } else {
      ElMessage.error(res.data.msg || '密码重置失败')
    }
  } catch (error) {
    if (error !== 'cancel') {
      console.error('重置密码失败:', error)
      ElMessage.error('重置密码失败')
    }
  }
}

// 删除用户
const handleDelete = async (row) => {
  try {
    await ElMessageBox.confirm('确定要删除该用户吗？此操作不可恢复！', '警告', {
      type: 'warning',
      confirmButtonText: '确定',
      cancelButtonText: '取消'
    })
    const res = await request.delete(`/api/user/${row.id}`)

    if (res.data.code === 200) {
      ElMessage.success('删除成功')
      fetchUsers() // 重新加载用户列表
    } else {
      ElMessage.error(res.msg || '删除失败')
    }
  } catch (error) {
    if (error !== 'cancel') {
      console.error('删除用户失败:', error)
      ElMessage.error('删除失败')
    }
  }
}

// 打开添加用户对话框
const openAddUserDialog = () => {
  addUserDialogVisible.value = true
}

// 重置添加用户表单
const resetAddUserForm = () => {
  if (addUserFormRef.value) {
    addUserFormRef.value.resetFields()
  }
  addUserForm.username = ''
  addUserForm.password = ''
  addUserForm.email = ''
  addUserForm.nickname = ''
  addUserForm.phone = ''
  addUserForm.gender = 2
  addUserForm.role = '2'
  addUserForm.status = 1
}

// 生成用户ID (时间戳+4位随机数)
const generateUserId = () => {
  return String(Date.now()) + String(Math.floor(Math.random() * 10000)).padStart(4, '0')
}

// 生成MySQL兼容的日期时间格式 (YYYY-MM-DD HH:MM:SS)
const formatMySQLDateTime = (date) => {
  const d = date || new Date()
  const year = d.getFullYear()
  const month = String(d.getMonth() + 1).padStart(2, '0')
  const day = String(d.getDate()).padStart(2, '0')
  const hours = String(d.getHours()).padStart(2, '0')
  const minutes = String(d.getMinutes()).padStart(2, '0')
  const seconds = String(d.getSeconds()).padStart(2, '0')
  return `${year}-${month}-${day} ${hours}:${minutes}:${seconds}`
}

// 提交添加用户
const submitAddUser = async () => {
  try {
    // 表单验证
    await addUserFormRef.value.validate()
    
    addUserLoading.value = true
    
    // 使用当前时间
    const now = formatMySQLDateTime(new Date())
    
    // 构造用户数据
    const userData = {
      id: generateUserId(),
      username: addUserForm.username,
      password: addUserForm.password, // 后端会自动加密
      email: addUserForm.email,
      nickname: addUserForm.nickname || addUserForm.username,
      phone: addUserForm.phone || '', // 确保phone字段有值
      bio: '', // 添加bio字段
      gender: addUserForm.gender,
      status: addUserForm.status,
      avatar: 'default.jpg', // 默认头像
      createdTime: now,
      updatedTime: now,
      lastLoginTime: now,
      roleId: addUserForm.role // 对应后端处理的角色ID
    }
    
    console.log('添加用户数据:', userData) // 调试用，查看提交的数据
    
    // 调用添加用户接口
    const res = await request.post('/api/user/add', userData)
    
    if (res.data.code === 200) {
      ElMessage.success('添加用户成功')
      addUserDialogVisible.value = false
      fetchUsers() // 重新加载用户列表
    } else {
      ElMessage.error(res.data.msg || '添加用户失败')
    }
  } catch (error) {
    console.error('添加用户失败:', error)
    ElMessage.error('添加用户失败')
  } finally {
    addUserLoading.value = false
  }
}

// 编辑用户相关数据
const editUserDialogVisible = ref(false)
const editUserFormRef = ref(null)
const editUserLoading = ref(false)
const editUserForm = reactive({
  username: '',
  password: '',
  email: '',
  nickname: '',
  phone: '',
  gender: 2,
  roleId: '2',
  status: 1
})

// 编辑用户表单验证规则
const editUserRules = {
  username: [
    { required: true, message: '请输入用户名', trigger: 'blur' },
    { min: 3, max: 20, message: '用户名长度应为3-20个字符', trigger: 'blur' }
  ],
  email: [
    { required: true, message: '请输入邮箱', trigger: 'blur' },
    { type: 'email', message: '请输入正确的邮箱格式', trigger: 'blur' }
  ],
  nickname: [
    { required: true, message: '请输入昵称', trigger: 'blur' },
    { min: 2, max: 20, message: '昵称长度应为2-20个字符', trigger: 'blur' }
  ],
  phone: [
    { pattern: /^1[3-9]\d{9}$/, message: '请输入正确的手机号码', trigger: 'blur' }
  ],
  roleId: [
    { required: true, message: '请选择用户角色', trigger: 'change' }
  ],
  status: [
    { required: true, message: '请选择用户状态', trigger: 'change' }
  ]
}

// 重置编辑用户表单
const resetEditUserForm = () => {
  if (editUserFormRef.value) {
    editUserFormRef.value.resetFields()
  }
  editUserForm.username = ''
  editUserForm.password = ''
  editUserForm.email = ''
  editUserForm.nickname = ''
  editUserForm.phone = ''
  editUserForm.gender = 2
  editUserForm.roleId = '2'
  editUserForm.status = 1
}

// 提交编辑用户
const submitEditUser = async () => {
  try {
    // 表单验证
    await editUserFormRef.value.validate()
    
    editUserLoading.value = true
    
    // 构造用户数据
    const userData = {
      id: editUserForm.id,
      username: editUserForm.username,
      password: editUserForm.password, // 留空表示不修改密码
      email: editUserForm.email,
      nickname: editUserForm.nickname,
      phone: editUserForm.phone,
      gender: editUserForm.gender,
      roleId: editUserForm.roleId,
      status: editUserForm.status
    }
    
    console.log('编辑用户数据:', userData) // 调试用，查看提交的数据
    
    // 调用编辑用户接口 - 使用直接更新API
    const res = await request.put('/api/user/update', userData)
    
    if (res.data.code === 200) {
      ElMessage.success('编辑用户成功')
      editUserDialogVisible.value = false
      fetchUsers() // 重新加载用户列表
    } else {
      ElMessage.error(res.data.msg || '编辑用户失败')
    }
  } catch (error) {
    console.error('编辑用户失败:', error)
    ElMessage.error('编辑用户失败')
  } finally {
    editUserLoading.value = false
  }
}

// 打开编辑用户对话框
const handleEdit = (row) => {
  // 填充表单数据
  editUserForm.id = row.id
  editUserForm.username = row.username
  editUserForm.password = '' // 密码留空表示不修改
  editUserForm.email = row.email
  editUserForm.nickname = row.nickname || ''
  editUserForm.phone = row.phone || ''
  editUserForm.gender = row.gender || 2
  editUserForm.status = row.status
  
  // 处理角色
  if (row.roles && row.roles.includes('ROLE_ADMIN')) {
    editUserForm.roleId = '1'
  } else {
    editUserForm.roleId = '2'
  }
  
  // 显示对话框
  editUserDialogVisible.value = true
}

// 初始化
onMounted(() => {
  fetchUsers()
})
</script>

<style lang="scss" scoped>
.users-container {
  padding: 20px;

  .search-bar {
    margin-bottom: 20px;
  }

  .user-info {
    display: flex;
    align-items: center;
    gap: 12px;

    .info {
      .name {
        font-size: 14px;
        font-weight: 500;
        margin-bottom: 4px;
      }
      .email {
        font-size: 12px;
        color: #999;
      }
    }
  }

  .mr-1 {
    margin-right: 4px;
  }

  .pagination {
    margin-top: 20px;
    display: flex;
    justify-content: flex-end;
  }
}
</style>
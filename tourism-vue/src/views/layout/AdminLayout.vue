<template>
  <div class="admin-layout">
    <el-container>
      <!-- Sidebar Section -->
      <el-aside width="240px" class="sidebar">
        <div class="logo">Admin Panel</div>
        <el-menu :default-active="activeMenu" class="el-menu-vertical-demo" @select="handleSelect">
          <el-menu-item index="users">
            <el-icon><User /></el-icon>
            <span>用户管理</span>
          </el-menu-item>
          <el-menu-item index="spots">
            <el-icon><Location /></el-icon>
            <span>景点管理</span>
          </el-menu-item>
          <el-menu-item index="orders">
            <el-icon><Ticket /></el-icon>
            <span>订单管理</span>
          </el-menu-item>
          <el-menu-item index="guides">
            <el-icon><Document /></el-icon>
            <span>攻略管理</span>
          </el-menu-item>
        </el-menu>
      </el-aside>

      <!-- Main Content Section -->
      <el-container>
        <el-header class="header">
          <div class="header-left">
            <el-breadcrumb separator="/">
              <el-breadcrumb-item v-for="item in breadcrumbs" :key="item">{{ item }}</el-breadcrumb-item>
            </el-breadcrumb>
          </div>
          <div class="header-right">
            <el-dropdown class="avatar-container" trigger="click">
              <div class="avatar-wrapper">
                <el-avatar :size="40" :src="userAvatar">
                  <img src="../.././assets/logo.jpg"/>
                </el-avatar>
                <span class="nickname">{{ userName }}</span>
                <el-icon><CaretBottom /></el-icon>
              </div>
              <template #dropdown>
                <el-dropdown-menu>
                  <el-dropdown-item @click="handleProfile">
                    <el-icon><User /></el-icon>个人信息
                  </el-dropdown-item>
                  <el-dropdown-item divided @click="handleLogout">
                    <el-icon><SwitchButton /></el-icon>退出登录
                  </el-dropdown-item>
                </el-dropdown-menu>
              </template>
            </el-dropdown>
          </div>
        </el-header>

        <el-main class="main-content">
          <!-- Content from router -->
          <router-view />
        </el-main>
      </el-container>
    </el-container>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { User, Location, Ticket, Document, Setting, SwitchButton, CaretBottom } from '@element-plus/icons-vue'
import request from '@/utils/request' // 假设你有一个封装的请求工具

const router = useRouter()

const activeMenu = ref('dashboard')
const breadcrumbs = ref(['首页'])
const userAvatar = ref('https://example.com/avatar.jpg')
const userName = ref('管理员')

// 定义菜单索引和对应面包屑名称的映射
const menuBreadcrumbMap = {
  'users': '用户管理',
  'spots': '景点管理',
  'orders': '订单管理',
  'guides': '攻略管理'
}

const handleSelect = (index) => {
  // 更新激活的菜单
  activeMenu.value = index
  // 根据菜单索引更新面包屑导航
  if (menuBreadcrumbMap[index]) {
    breadcrumbs.value = ['首页', menuBreadcrumbMap[index]]
  }
  router.push(`/admin/${index}`)
}

// 处理个人信息
const handleProfile = () => {
  breadcrumbs.value = ['首页', '个人信息']
  router.push('/admin/profile')
}



// 处理退出登录
const handleLogout = async () => {
  try {
    await request.post('/api/auth/logout')
    localStorage.removeItem('token')
    localStorage.removeItem('userRole')
    router.push('/login')
    ElMessage.success('已成功退出登录')
  } catch (error) {
    ElMessage.error('退出登录失败，请稍后重试')
  }
}
</script>

<style scoped>
.admin-layout {
  .sidebar {
    background-color: #f5f5f5;
    padding: 20px;
    .logo {
      font-size: 24px;
      font-weight: bold;
      margin-bottom: 20px;
      text-align: center;
    }
    .el-menu {
      border-right: none;
    }
  }
  .header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 0 20px;
    background-color: #fff;
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
    .header-left {
      display: flex;
      align-items: center;
    }
    .header-right {
      display: flex;
      align-items: center;
    }
  }
  .main-content {
    padding: 20px;
    background-color: #f0f2f5;
  }
}

.avatar-container {
  cursor: pointer;

  .avatar-wrapper {
    display: flex;
    align-items: center;
    gap: 8px;
    padding: 5px 8px;

    &:hover {
      background: rgba(0,0,0,.025);
    }

    .nickname {
      font-size: 14px;
      color: #333;
    }

    .el-icon {
      font-size: 12px;
      color: #666;
    }
  }
}

:deep(.el-dropdown-menu__item) {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 16px;

  .el-icon {
    font-size: 16px;
  }
}
</style>
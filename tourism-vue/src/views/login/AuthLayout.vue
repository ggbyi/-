<template>
  <div class="auth-container">
    <div class="auth-content">
      <!-- Logo -->
      <div class="logo">
        <img src="../../assets/logo.jpg" alt="Logo">
        <h1>旅游推荐系统</h1>
      </div>
      
      <!-- 路由出口 -->
      <router-view />
      
      <!-- 底部链接 -->
      <div class="bottom-links">
        <router-link to="#">关于我们</router-link>
        <router-link to="#">隐私政策</router-link>
        <router-link to="#">服务条款</router-link>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'AuthLayout'
}
</script>

<style lang="scss" scoped>
.auth-container {
  min-height: 100vh;
  display: flex;
  justify-content: center;
  align-items: center;
  background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
  padding: 20px;

  .auth-content {
    width: 100%;
    max-width: 400px;
    text-align: center;

    .logo {
      margin-bottom: 30px;

      img {
        width: 80px;
        height: 80px;
        margin-bottom: 12px;
      }

      h1 {
        font-size: 24px;
        color: #333;
      }
    }

    .bottom-links {
      margin-top: 24px;
      display: flex;
      justify-content: center;
      gap: 16px;
      font-size: 14px;

      a {
        color: #666;
        text-decoration: none;

        &:hover {
          color: var(--el-color-primary);
        }
      }
    }
  }
}
</style> 
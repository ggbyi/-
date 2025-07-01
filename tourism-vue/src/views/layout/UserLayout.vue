<template>
  <div class="user-layout">
    <!-- 背景特效 -->
    <div class="animated-background">
      <div class="floating-element plane"></div>
      <div class="floating-element cloud1"></div>
      <div class="floating-element cloud2"></div>
      <div class="floating-element balloon"></div>
      <div class="floating-element mountain"></div>
      
      <!-- 粒子特效 -->
      <div class="particles-container">
        <div v-for="i in 20" :key="i" :class="`particle p${i}`"></div>
      </div>
      
      <!-- 光效装饰 -->
      <div class="light-effect light1"></div>
      <div class="light-effect light2"></div>
      <div class="light-effect light3"></div>
    </div>
    
    <el-container>
      <!-- 顶部导航栏 -->
      <el-header class="header">
        <div class="header-left">
          <div class="logo">
            <img src="@/assets/logo.jpg" alt="logo">
            <span>遇见旅行</span>
            <div class="logo-tagline">探索世界的每一个角落</div>
          </div>
          
          <!-- 旅行主题标签 -->
          <div class="travel-tags">
            <span class="travel-tag">自然风光</span>
            <span class="travel-tag">人文历史</span>
            <span class="travel-tag">美食之旅</span>
            <span class="travel-tag">海岛度假</span>
          </div>
        </div>

        <!-- 导航菜单 -->
        <el-menu 
          :default-active="activeMenu" 
          mode="horizontal" 
          class="nav-menu"
          @select="handleSelect"
        >
          <el-menu-item index="explore">
            <el-icon><Compass /></el-icon>
            <span>发现</span>
            <div class="menu-indicator"></div>
          </el-menu-item>
          <el-menu-item index="guides">
            <el-icon><Document /></el-icon>
            <span>攻略</span>
            <div class="menu-indicator"></div>
          </el-menu-item>
          <el-menu-item index="orders">
            <el-icon><Tickets /></el-icon>
            <span>订单</span>
            <div class="menu-indicator"></div>
          </el-menu-item>
        </el-menu>

        <div class="user-area">
          <div class="notification">
            <el-badge :value="notificationCount" class="notification-badge" v-if="notificationCount > 0">
              <el-icon><Bell /></el-icon>
            </el-badge>
            <el-icon v-else><Bell /></el-icon>
          </div>

          <el-dropdown class="avatar-container" trigger="click" @command="handleCommand">
            <div class="avatar-wrapper">
              <div class="avatar-border">
                <el-avatar :src="userAvatar" :size="40">
                  <img src="@/assets/logo.jpg"/>
                </el-avatar>
              </div>
              <div class="user-info">
                <span class="username">{{ userName }}</span>
                <span class="user-level">旅行家</span>
              </div>
              <el-icon><CaretBottom /></el-icon>
            </div>
            <template #dropdown>
              <el-dropdown-menu class="custom-dropdown">
                <el-dropdown-item command="profile">
                  <el-icon><User /></el-icon>个人主页
                </el-dropdown-item>
                <el-dropdown-item command="settings">
                  <el-icon><Setting /></el-icon>账号设置
                </el-dropdown-item>
                <el-dropdown-item command="logout" divided>
                  <el-icon><SwitchButton /></el-icon>退出登录
                </el-dropdown-item>
              </el-dropdown-menu>
            </template>
          </el-dropdown>

          <el-button type="primary" class="publish-btn" @click="handlePublish">
            <el-icon><Plus /></el-icon>发布游记
          </el-button>
        </div>
      </el-header>

      <!-- 轮播图区域 -->
      <div class="banner-section" v-if="$route.path === '/user/explore'">
        <div class="banner-decoration left"></div>
        <div class="banner-decoration right"></div>
        <el-carousel 
          :interval="4000" 
          type="card" 
          height="320px"
          :autoplay="true"
          indicator-position="outside"
          class="modern-carousel"
        >
          <el-carousel-item v-for="item in carouselItems" :key="item.id">
            <div class="carousel-content" :style="{ backgroundImage: `url(${item.imageUrl})` }">
              <div class="content-overlay">
                <div class="content-tag">{{ item.tag }}</div>
                <h2>{{ item.title }}</h2>
                <p>{{ item.description }}</p>
              </div>
            </div>
          </el-carousel-item>
        </el-carousel>


      </div>

      <!-- 主要内容区域 -->
      <el-main class="main-content" :class="{ 'with-banner': $route.path === '/user/explore' }">
        <router-view v-slot="{ Component }">
          <transition name="fade" mode="out-in">
            <component :is="Component" />
          </transition>
        </router-view>
      </el-main>
      
      <!-- 页脚 -->
      <el-footer class="footer" v-if="$route.path === '/user/explore'">
        <div class="footer-content">
          <div class="footer-section">
            <h3>关于我们</h3>
            <p>遇见旅行致力于为用户提供高质量的旅游体验与服务</p>
          </div>
          <div class="footer-section">
            <h3>快速链接</h3>
            <ul>
              <li>景点推荐</li>
              <li>热门攻略</li>
              <li>用户反馈</li>
            </ul>
          </div>
          <div class="footer-section">
            <h3>联系我们</h3>
            <p>邮箱: contact@tourism.com</p>
            <p>电话: 400-800-8888</p>
          </div>
        </div>
        <div class="copyright">
          © 2023 遇见旅行 All Rights Reserved
        </div>
      </el-footer>
    </el-container>
  </div>
</template>

<script setup>
import { ref, watch, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { ElMessage } from 'element-plus'
import {
  Search, Camera, Compass, Location, Document,
  ChatDotRound, Tickets, Bell, User, Setting,
  Star, SwitchButton, Plus, CaretBottom, ArrowRight,
  Place, Promotion, Collection, Calendar, Sunny,
  Microphone, Ship, Umbrella, Mug, MapLocation,
  PictureFilled, Suitcase, Postcard
} from '@element-plus/icons-vue'
import request from '@/utils/request'

// 导入图片资源
import alipayImg from '@/assets/fj.jpg'
import wechatImg from '@/assets/wh.jpg'
import logoImg from '@/assets/ms.jpg'

const router = useRouter()
const route = useRoute()
const activeMenu = ref('explore')
const searchKeyword = ref('')
const userAvatar = ref('http://localhost:5173/api/file/default.jpg')
const userName = ref('旅行者')
const notificationCount = ref(0)

// 轮播图数据
const carouselItems = ref([
  {
    id: 1,
    title: '探索自然奇观',
    description: '发现世界上最令人惊叹的自然景观',
    imageUrl: alipayImg,
    tag: '自然风光'
  },
  {
    id: 2,
    title: '文化之旅',
    description: '体验独特的文化遗产和历史故事',
    imageUrl: wechatImg,
    tag: '文化探索'
  },
  {
    id: 3,
    title: '美食探索',
    description: '品味各地特色美食，感受舌尖上的旅行',
    imageUrl: logoImg,
    tag: '美食之旅'
  }
])

// 设置粒子随机位置和属性
onMounted(() => {
  const particles = document.querySelectorAll('.particle')
  particles.forEach((particle, index) => {
    const size = Math.floor(Math.random() * 6) + 2
    const duration = Math.floor(Math.random() * 20) + 10
    const delay = Math.floor(Math.random() * 10)
    const opacity = (Math.floor(Math.random() * 6) + 4) * 0.1
    const travel = Math.floor(Math.random() * 80) + 20
    const left = Math.floor(Math.random() * 100)
    const top = Math.floor(Math.random() * 100)
    
    // 设置CSS变量
    particle.style.setProperty('--size', `${size}px`)
    particle.style.setProperty('--duration', `${duration}s`)
    particle.style.setProperty('--delay', `${delay}s`)
    particle.style.setProperty('--opacity', opacity)
    particle.style.left = `${left}%`
    particle.style.top = `${top}%`
    
    // 设置不同颜色
    if (index % 3 === 0) {
      particle.style.background = 'linear-gradient(45deg, #ff6b81, #ff4757)'
    } else if (index % 3 === 1) {
      particle.style.background = 'linear-gradient(45deg, #4fc3f7, #2196f3)'
    } else {
      particle.style.background = 'linear-gradient(45deg, #ffeb3b, #ffc107)'
    }
  })
})

// 导航菜单处理
const handleSelect = (key) => {
  router.push({
    path: `/user/${key}`
  })
}

// 用户下拉菜单处理
const handleCommand = (command) => {
  if (command === 'logout') {
    // 处理登出逻辑
    localStorage.removeItem('user')
    localStorage.removeItem('token')
    router.push('/login')
  } else if (command === 'profile') {
    router.push('/user/profile')
  } else if (command === 'settings') {
    router.push('/user/settings')
  }
}

// 发布游记
const handlePublish = () => {
  router.push('/user/publish')
}

// 路由变化时，更新激活的菜单项
watch(() => route.path, (newPath) => {
  const path = newPath.split('/')[2]
  if (path) {
    activeMenu.value = path
  }
}, { immediate: true })
</script>

<style lang="scss" scoped>
.user-layout {
  min-height: 100vh;
  background-color: #f8f9fa;
  position: relative;
  overflow-x: hidden;
  
  /* 动画背景 */
  .animated-background {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    z-index: 0;
    overflow: hidden;
    background: linear-gradient(165deg, #e0f7fa 0%, #bbdefb 50%, #90caf9 100%);
    
    /* 粒子容器样式 */
    .particles-container {
      position: absolute;
      top: 0;
      left: 0;
      width: 100%;
      height: 100%;
      overflow: hidden;
      z-index: 1;
    }
    
    /* 粒子基础样式 */
    .particle {
      position: absolute;
      border-radius: 50%;
      background: white;
      opacity: 0;
      pointer-events: none;
      z-index: 2;
      box-shadow: 0 0 10px 2px rgba(255, 255, 255, 0.8);
      width: var(--size);
      height: var(--size);
      opacity: var(--opacity);
      animation-delay: var(--delay);
      animation-duration: var(--duration);
      animation-timing-function: linear;
      animation-iteration-count: infinite;
      animation-name: float, pulse;
    }
    
    /* 光效装饰 */
    .light-effect {
      position: absolute;
      border-radius: 50%;
      filter: blur(50px);
      opacity: 0.15;
      pointer-events: none;
      
      &.light1 {
        top: 15%;
        left: 10%;
        width: 300px;
        height: 300px;
        background: radial-gradient(circle, rgba(255,107,129,0.8) 0%, rgba(255,107,129,0) 70%);
        animation: pulse 8s infinite alternate;
      }
      
      &.light2 {
        bottom: 20%;
        right: 15%;
        width: 400px;
        height: 400px;
        background: radial-gradient(circle, rgba(79,195,247,0.8) 0%, rgba(79,195,247,0) 70%);
        animation: pulse 12s infinite alternate-reverse;
      }
      
      &.light3 {
        top: 40%;
        left: 50%;
        width: 350px;
        height: 350px;
        background: radial-gradient(circle, rgba(255,235,59,0.8) 0%, rgba(255,235,59,0) 70%);
        animation: pulse 10s infinite alternate;
      }
    }
    
    /* 浮动元素 */
    .floating-element {
      position: absolute;
      opacity: 0.15;
      pointer-events: none;
      
      &.plane {
        top: 15%;
        left: 10%;
        width: 80px;
        height: 80px;
        background: url('@/assets/logo.jpg') no-repeat center center;
        background-size: contain;
        animation: floatAndRotate 15s infinite ease-in-out;
      }
      
      &.cloud1 {
        top: 25%;
        right: 15%;
        width: 100px;
        height: 60px;
        background: #fff;
        border-radius: 50px;
        animation: floatSideways 20s infinite ease-in-out;
      }
      
      &.cloud2 {
        bottom: 30%;
        left: 20%;
        width: 80px;
        height: 50px;
        background: #fff;
        border-radius: 40px;
        animation: floatSideways 18s infinite ease-in-out reverse;
      }
      
      &.balloon {
        top: 40%;
        right: 30%;
        width: 40px;
        height: 60px;
        background: linear-gradient(45deg, #ff6b81, #ff4757);
        border-radius: 50% 50% 50% 50% / 60% 60% 40% 40%;
        animation: floatUp 12s infinite ease-in-out;
      }
      
      &.mountain {
        bottom: -5%;
        left: 0;
        width: 100%;
        height: 100px;
        background: linear-gradient(180deg, transparent 0%, #48dbfb 100%);
        clip-path: polygon(0% 100%, 15% 80%, 30% 90%, 50% 70%, 70% 85%, 85% 75%, 100% 100%);
      }
    }
  }
  
  /* 顶部导航栏 */
  .header {
    height: auto;
    padding: 15px 40px;
    display: flex;
    align-items: center;
    justify-content: space-between;
    position: relative;
    z-index: 10;
    background: rgba(255, 255, 255, 0.8);
    backdrop-filter: blur(10px);
    box-shadow: 0 4px 30px rgba(0, 0, 0, 0.1);
    
    .header-left {
      display: flex;
      align-items: center;
      
      .logo {
        display: flex;
        align-items: center;
        position: relative;
        
        img {
          width: 40px;
          height: 40px;
          border-radius: 50%;
          margin-right: 10px;
          object-fit: cover;
        }
        
        span {
          font-size: 20px;
          font-weight: 600;
          color: #333;
          background: linear-gradient(45deg, #ff4757, #ff6b81);
          -webkit-background-clip: text;
          -webkit-text-fill-color: transparent;
        }
        
        .logo-tagline {
          position: absolute;
          bottom: -15px;
          left: 50px;
          font-size: 12px;
          color: #666;
          white-space: nowrap;
        }
      }
      
      .travel-tags {
        display: flex;
        align-items: center;
        margin-left: 50px;
        
        .travel-tag {
          padding: 6px 12px;
          background: rgba(255, 255, 255, 0.7);
          border-radius: 20px;
          margin-right: 10px;
          font-size: 13px;
          color: #333;
          cursor: pointer;
          transition: all 0.3s;
          box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
          
          &:hover {
            background: linear-gradient(45deg, #ff4757, #ff6b81);
            color: white;
            box-shadow: 0 4px 12px rgba(255, 71, 87, 0.3);
          }
        }
      }
    }
    
    .nav-menu {
      background: transparent;
      border-bottom: none;
      margin-right: 20px;
      
      .el-menu-item {
        font-size: 15px;
        color: #555;
        height: 50px;
        line-height: 50px;
        position: relative;
        
        .el-icon {
          margin-right: 5px;
        }
        
        .menu-indicator {
          position: absolute;
          bottom: 0;
          left: 50%;
          transform: translateX(-50%) scaleX(0);
          height: 3px;
          width: 20px;
          background: linear-gradient(45deg, #ff4757, #ff6b81);
          border-radius: 2px;
          transition: transform 0.3s;
        }
        
        &.is-active {
          color: #ff4757 !important;
          
          .menu-indicator {
            transform: translateX(-50%) scaleX(1);
          }
        }
        
        &:hover {
          background: transparent;
          color: #ff4757;
        }
      }
    }
    
    .user-area {
      display: flex;
      align-items: center;
      
      .notification {
        position: relative;
        margin-right: 20px;
        cursor: pointer;
        
        .el-icon {
          font-size: 22px;
          color: #555;
          transition: color 0.3s;
          
          &:hover {
            color: #ff4757;
          }
        }
      }
      
      .avatar-container {
        margin-right: 20px;
        
        .avatar-wrapper {
          display: flex;
          align-items: center;
          cursor: pointer;
          
          .avatar-border {
            padding: 2px;
            border-radius: 50%;
            background: linear-gradient(45deg, #ff4757, #ff6b81);
            margin-right: 10px;
          }
          
          .user-info {
            display: flex;
            flex-direction: column;
            margin-right: 5px;
            
            .username {
              font-size: 14px;
              font-weight: 500;
              color: #333;
            }
            
            .user-level {
              font-size: 12px;
              color: #666;
            }
          }
        }
      }

      .publish-btn {
        border-radius: 24px;
        padding: 8px 24px;
        background: linear-gradient(45deg, #ff4757, #ff6b81);
        border: none;
        font-weight: 500;
        box-shadow: 0 4px 10px rgba(255, 71, 87, 0.3);
        transform: translateY(0);
        transition: all 0.3s cubic-bezier(0.175, 0.885, 0.32, 1.275);
        
        &:hover {
          opacity: 0.95;
          transform: translateY(-3px);
          box-shadow: 0 6px 15px rgba(255, 71, 87, 0.4);
        }
        
        &:active {
          transform: translateY(-1px);
        }
      }
    }
  }

  /* 轮播图区域 */
  .banner-section {
    position: relative;
    padding: 30px 40px 60px;
    z-index: 1;
    
    .banner-decoration {
      position: absolute;
      width: 200px;
      height: 200px;
      background: linear-gradient(45deg, #ff4757, #ff6b81);
      border-radius: 50%;
      filter: blur(100px);
      opacity: 0.1;
      
      &.left {
        top: 10%;
        left: 5%;
      }
      
      &.right {
        bottom: 20%;
        right: 5%;
      }
    }
    
    .modern-carousel {
      .carousel-content {
        height: 100%;
        background-size: cover;
        background-position: center;
        border-radius: 12px;
        position: relative;
        overflow: hidden;
        
        &:hover .content-overlay {
          background: linear-gradient(0deg, rgba(0,0,0,0.7) 0%, rgba(0,0,0,0.4) 50%, rgba(0,0,0,0) 100%);
        }
        
        .content-overlay {
          position: absolute;
          bottom: 0;
          left: 0;
          right: 0;
          padding: 40px;
          background: linear-gradient(0deg, rgba(0,0,0,0.7) 0%, rgba(0,0,0) 100%);
          color: white;
          text-align: left;
          transition: background 0.3s;
          
          .content-tag {
            display: inline-block;
            padding: 6px 12px;
            background: rgba(255, 71, 87, 0.8);
            border-radius: 20px;
            font-size: 12px;
            margin-bottom: 10px;
          }
          
          h2 {
            font-size: 28px;
            font-weight: 600;
            margin-bottom: 10px;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
          }
          
          p {
            font-size: 16px;
            opacity: 0.9;
          }
        }
      }
    }
    
    /* 装饰性旅行图标 */
    .travel-icons {
      display: flex;
      justify-content: center;
      margin-top: 20px;
      
      .icon-item {
        width: 50px;
        height: 50px;
        background: white;
        border-radius: 50%;
        display: flex;
        align-items: center;
        justify-content: center;
        margin: 0 15px;
        box-shadow: 0 5px 15px rgba(0,0,0,0.1);
        transition: all 0.3s;
        
        .el-icon {
          font-size: 24px;
          color: #ff4757;
        }
        
        &:nth-child(1) {
          animation: pulse 5s infinite alternate;
        }
        
        &:nth-child(2) {
          animation: pulse 7s infinite alternate-reverse;
        }
        
        &:nth-child(3) {
          animation: pulse 6s infinite alternate;
        }
        
        &:nth-child(4) {
          animation: pulse 8s infinite alternate-reverse;
        }
        
        &:hover {
          transform: translateY(-5px);
          box-shadow: 0 8px 20px rgba(255, 71, 87, 0.2);
          
          .el-icon {
            transform: scale(1.2);
          }
        }
      }
    }
  }
  
  // 主内容区域
  .main-content {
    margin-top: 80px;
    padding: 0 40px;
    min-height: calc(100vh - 80px);
    background: #f8f9fa;
    
    &.with-banner {
      margin-top: 20px;
    }
  }
  
  // 页脚
  .footer {
    background: #2c3e50;
    color: white;
    padding: 40px 0 20px;
    margin-top: 40px;
    
    .footer-content {
      display: flex;
      justify-content: space-around;
      flex-wrap: wrap;
      max-width: 1200px;
      margin: 0 auto;
      padding: 0 20px;
      
      .footer-section {
        flex: 1;
        min-width: 250px;
        margin-bottom: 30px;
        
        h3 {
          font-size: 18px;
          margin-bottom: 16px;
          position: relative;
          padding-bottom: 10px;
          
          &::after {
            content: '';
            position: absolute;
            bottom: 0;
            left: 0;
            width: 40px;
            height: 3px;
            background: #ff4757;
            border-radius: 1.5px;
          }
        }
        
        p {
          font-size: 14px;
          line-height: 1.6;
          color: #bdc3c7;
        }
        
        ul {
          list-style: none;
          padding: 0;
          margin: 0;
          
          li {
            margin-bottom: 8px;
            color: #bdc3c7;
            cursor: pointer;
            transition: color 0.3s;
            
            &:hover {
              color: #ff4757;
            }
          }
        }
      }
    }
    
    .copyright {
      text-align: center;
      margin-top: 20px;
      padding-top: 20px;
      border-top: 1px solid rgba(255,255,255,0.1);
      font-size: 14px;
      color: #7f8c8d;
    }
  }
}

:deep(.el-dropdown-menu) {
  border-radius: 12px;
  box-shadow: 0 4px 16px rgba(0,0,0,0.1);
  overflow: hidden;
  padding: 0;
  
  .el-dropdown-menu__item {
    display: flex;
    align-items: center;
    gap: 8px;
    padding: 12px 20px;
    
    &:hover {
      background: #f6f6f6;
    }
    
    .el-icon {
      font-size: 16px;
    }
  }
}

:deep(.el-carousel__indicators) {
  bottom: -30px;

  .el-carousel__button {
    width: 30px;
    height: 4px;
    border-radius: 2px;
    background: rgba(255, 71, 87, 0.5);
    transition: all 0.3s ease;

    &:hover {
      background: #ff4757;
    }
  }
}

:deep(.el-badge__content) {
  background-color: #ff4757;
}

.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.3s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}

@media screen and (max-width: 768px) {
  .banner-section {
    padding: 20px 15px 40px;

    .modern-carousel {
      height: 300px !important;
    }

    .carousel-content {
      .content-overlay {
        padding: 20px;

        h2 {
          font-size: 24px;
        }

        p {
          font-size: 16px;
        }
      }
    }
  }
  
  .main-content {
    padding: 0 15px 30px;
  }
}

@keyframes floatAndRotate {
  0% {
    transform: translateY(0) rotate(0deg);
  }
  50% {
    transform: translateY(-30px) rotate(5deg);
  }
  100% {
    transform: translateY(0) rotate(0deg);
  }
}

@keyframes floatSideways {
  0% {
    transform: translateX(0);
  }
  50% {
    transform: translateX(30px);
  }
  100% {
    transform: translateX(0);
  }
}

@keyframes floatUp {
  0% {
    transform: translateY(0);
  }
  50% {
    transform: translateY(-50px);
  }
  100% {
    transform: translateY(0);
  }
}

@keyframes float {
  0% {
    transform: translateY(0) translateX(0) rotate(0deg);
  }
  100% {
    transform: translateY(0) translateX(0) rotate(360deg);
  }
}

@keyframes pulse {
  0%, 100% {
    opacity: var(--opacity, 1);
    transform: scale(1);
  }
  50% {
    opacity: calc(var(--opacity, 1) * 0.6);
    transform: scale(0.8);
  }
}
</style>
import { createRouter, createWebHistory } from 'vue-router'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    // 登录注册相关
    {
      path: '',
      component: () => import('@/views/login/AuthLayout.vue'),
      children: [
        {
          path: '',
          redirect: '/login'
        },
        {
          path: 'login',
          name: 'Login',
          component: () => import('@/views/login/login.vue'),
          meta: { title: '登录' }
        },
        {
          path: 'register',
          name: 'Register',
          component: () => import('@/views/login/register.vue'),
          meta: { title: '注册' }
        },
        {
          path: 'forgot-password',
          name: 'ForgotPassword',
          component: () => import('@/views/login/forgot-password.vue'),
          meta: { title: '忘记密码' }
        }
      ]
    },

    // 用户端布局
    {
      path: '/user',
      component: () => import('@/views/layout/UserLayout.vue'),
      children: [
        {
          path: '',
          redirect: '/user/explore'
        },
        // 景点探索
        {
          path: 'explore',
          name: 'Explore',
          component: () => import('@/views/user/explore/index.vue'),
          meta: { title: '景点探索' }
        },
        // 个人中心
        {
          path: 'profile',
          name: 'UserProfile',
          component: () => import('@/views/user/profile/index.vue'),
          meta: { title: '个人中心' }
        },
        // 我的订单
        {
          path: 'orders',
          name: 'UserOrders',
          component: () => import('@/views/user/orders/index.vue'),
          meta: { title: '我的订单' }
        },
        // 旅游攻略
        {
          path: 'guides',
          name: 'TravelGuides',
          component: () => import('@/views/user/guides/index.vue'),
          meta: { title: '旅游攻略' }
        },
        {
          path: '/spot/:id',
          name: 'SpotDetail',
          component: () => import('@/views/user/spot/detail.vue'),
          meta: {
            title: '景点详情',
            requiresAuth: false
          }
        },
        // 添加攻略详情页路由
        {
          path: 'guides/:id',  // 使用动态路由参数
          name: 'GuideDetail',
          component: () => import('@/views/user/guides/detail.vue'),
          meta: { title: '攻略详情' }
        },
        {
          path: 'my-guides',
          name: 'MyGuides',
          component: () => import('@/views/user/guides/my.vue'),
          meta: { title: '我的攻略' }
        } ,
        {
          path: 'settings',
          name: 'settings',
          component: () => import('@/views/user/settings/index.vue'),
          meta: { title: '账号设置' }
        }
      ]
    },

    // 管理员端布局
    {
      path: '/admin',
      component: () => import('@/views/layout/AdminLayout.vue'),
      children: [
        {
          path: '',
          redirect: '/admin/dashboard'
        },

        // 用户管理
        {
          path: 'users',
          name: 'UserManagement',
          component: () => import('@/views/admin/users/index.vue'),
          meta: { title: '用户管理' }
        },
        // 景点管理
        {
          path: 'spots',
          name: 'SpotManagement',
          component: () => import('@/views/admin/spots/index.vue'),
          meta: { title: '景点管理' }
        },
        // 订单管理
        {
          path: 'orders',
          name: 'OrderManagement',
          component: () => import('@/views/admin/orders/index.vue'),
          meta: { title: '订单管理' }
        },
        // 攻略管理
        {
          path: 'guides',
          name: 'GuideManagement',
          component: () => import('@/views/admin/guides/index.vue'),
          meta: { title: '攻略管理' }
        },

        // 系统设置
        {
          path: 'profile',
          name: 'AdminProfile',
          component: () => import('@/views/admin/profile/index.vue'),
          meta: { title: '个人中心' }
        }
      ]
    }
  ]
})


export default router 
<template>
  <div class="profile-container">
    <!-- 个人信息头部 -->
    <div class="profile-header">
      <div class="user-info">
        <el-avatar 
          :size="100" 
          :src="userInfo.avatar"
          :alt="userInfo.nickname"
        >
          {{ userInfo.nickname?.charAt(0)?.toUpperCase() }}
        </el-avatar>
        <div class="info-content">
          <h2>{{ userInfo.nickname }}</h2>
          <p class="user-id">ID: {{ userInfo.userId }}</p>
          <p class="bio">{{ userInfo.bio }}</p>
          <div class="stats">
            <div class="stat-item">
              <div class="count">{{ userInfo.followingCount }}</div>
              <div class="label">关注</div>
            </div>
            <div class="stat-item">
              <div class="count">{{ userInfo.followerCount }}</div>
              <div class="label">粉丝</div>
            </div>
            <div class="stat-item">
              <div class="count">{{ userInfo.likeCount }}</div>
              <div class="label">获赞</div>
            </div>
          </div>
          <el-button type="primary" @click="showEditDialog" v-if="isCurrentUser">
            编辑资料
          </el-button>
        </div>
      </div>
    </div>

    <!-- 内容标签页 -->
    <div class="profile-content">
      <el-tabs v-model="activeTab" @tab-click="handleTabChange">
        <el-tab-pane label="我的攻略" name="guides">
          <div class="guides-grid" v-loading="loading">
            <div v-for="guide in guides" :key="guide.id" class="guide-item" @click="goToGuideDetail(guide.id)">
              <el-image :src="getMediaUrl(guide.coverUrl)" fit="cover">
                <template #error>
                  <div class="image-slot">
                    <el-icon><Picture /></el-icon>
                  </div>
                </template>
              </el-image>
              <div class="guide-info">
                <h3>{{ guide.title }}</h3>
                <div class="stats">
                  <span><el-icon><View /></el-icon>{{ guide.views }}</span>
                  <span><el-icon><Star /></el-icon>{{ guide.likes }}</span>
                </div>
              </div>
            </div>
          </div>
        </el-tab-pane>

        <el-tab-pane label="收藏景点" name="favorites">
          <div class="spots-grid" v-loading="loading">
            <div v-for="spot in favorites" :key="spot.id" class="spot-item" @click="goToSpotDetail(spot.id)">
              <el-image :src="getMediaUrl(spot.coverUrl)" fit="cover">
                <template #error>
                  <div class="image-slot">
                    <el-icon><Picture /></el-icon>
                  </div>
                </template>
              </el-image>
              <div class="spot-info">
                <h3>{{ spot.name }}</h3>
                <div class="price">¥{{ spot.price }}</div>
              </div>
            </div>
          </div>
        </el-tab-pane>

        <el-tab-pane label="点赞景点" name="likes">
          <div class="spots-grid" v-loading="loading">
            <div v-for="spot in likes" :key="spot.id" class="spot-item" @click="goToSpotDetail(spot.id)">
              <el-image :src="getMediaUrl(spot.coverUrl)" fit="cover">
                <template #error>
                  <div class="image-slot">
                    <el-icon><Picture /></el-icon>
                  </div>
                </template>
              </el-image>
              <div class="spot-info">
                <h3>{{ spot.name }}</h3>
                <div class="price">¥{{ spot.price }}</div>
              </div>
            </div>
          </div>
        </el-tab-pane>
      </el-tabs>

      <!-- 加载更多 -->
      <div class="load-more" v-if="hasMore && !loading">
        <el-button type="primary" text @click="loadMore">
          加载更多 <el-icon class="el-icon--right"><ArrowDown /></el-icon>
        </el-button>
      </div>
    </div>

    <!-- 编辑资料对话框 -->
    <el-dialog
      v-model="editDialog.visible"
      title="编辑个人资料"
      width="500px"
    >
      <el-form :model="editDialog.form" label-width="80px">
        <el-form-item label="头像">
          <el-upload
            class="avatar-uploader"
            action="/api/upload"
            :show-file-list="false"
            :on-success="handleAvatarSuccess"
            :before-upload="beforeAvatarUpload"
          >
            <img v-if="editDialog.form.avatar" :src="editDialog.form.avatar" class="avatar" />
            <el-icon v-else class="avatar-uploader-icon"><Plus /></el-icon>
          </el-upload>
        </el-form-item>
        
        <el-form-item label="昵称">
          <el-input v-model="editDialog.form.nickname" maxlength="20" show-word-limit />
        </el-form-item>

        <el-form-item label="性别">
          <el-radio-group v-model="editDialog.form.gender">
            <el-radio :label="1">男</el-radio>
            <el-radio :label="2">女</el-radio>
            <el-radio :label="0">保密</el-radio>
          </el-radio-group>
        </el-form-item>

        <el-form-item label="手机号">
          <el-input v-model="editDialog.form.phone" maxlength="11" />
        </el-form-item>
        
        <el-form-item label="个性签名">
          <el-input
            v-model="editDialog.form.bio"
            type="textarea"
            maxlength="100"
            show-word-limit
            :rows="3"
          />
        </el-form-item>
      </el-form>
      
      <template #footer>
        <el-button @click="editDialog.visible = false">取消</el-button>
        <el-button type="primary" @click="handleUpdateProfile" :loading="editDialog.loading">
          保存
        </el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import {
  View, Star, Picture, Plus, ArrowDown
} from '@element-plus/icons-vue'
import request from '@/utils/request'

const route = useRoute()
const router = useRouter()

// 用户信息
const userInfo = ref({})
const isCurrentUser = ref(false)

// 标签页相关
const activeTab = ref('guides')
const loading = ref(false)
const page = ref(1)
const pageSize = ref(12)
const hasMore = ref(true)

// 内容列表
const guides = ref([])
const favorites = ref([])
const likes = ref([])

// 编辑对话框
const editDialog = reactive({
  visible: false,
  loading: false,
  form: {
    avatar: '',
    nickname: '',
    gender: 0,
    phone: '',
    bio: ''
  }
})

// 获取用户信息
const getUserInfo = async () => {
  try {
    const { data: res } = await request.get('/api/user/info')
    if (res.code === 200) {
      // 直接使用返回的对象
      userInfo.value = {
        ...res.data,
        // 处理头像路径
        avatar: res.data.avatar ? (res.data.avatar.startsWith('http') ? 
          res.data.avatar : `/api/file/${res.data.avatar}`) : '',
        // 设置默认值
        followingCount: res.data.followingCount || 0,
        followerCount: res.data.followerCount || 0,
        likeCount: res.data.likeCount || 0,
        bio: res.data.bio || '这个人很懒，什么都没写~'
      }
      
      // 初始化编辑表单
      editDialog.form = {
        avatar: userInfo.value.avatar,
        nickname: userInfo.value.nickname,
        gender: userInfo.value.gender || 0,
        phone: userInfo.value.phone || '',
        bio: userInfo.value.bio
      }
    }
  } catch (error) {
    console.error('获取用户信息失败:', error)
    ElMessage.error('获取用户信息失败')
  }
}

// 获取内容列表
const getContentList = async () => {
  if (loading.value) return
  
  try {
    loading.value = true
    const params = {
      page: page.value,
      pageSize: pageSize.value
    }
    
    let url = ''
    switch (activeTab.value) {
      case 'guides':
        url = '/api/guide/my'
        break
      case 'favorites':
        url = '/api/spots/favorites'  // 修改为正确的接口路径
        break
      case 'likes':
        url = '/api/spots/likes'  // 修改为正确的接口路径
        break
    }
    
    const { data: res } = await request.get(url, { params })
    
    if (res.code === 200) {
      const list = res.data.records || []
      if (activeTab.value === 'guides') {
        guides.value = page.value === 1 ? list : [...guides.value, ...list]
      } else if (activeTab.value === 'favorites') {
        favorites.value = page.value === 1 ? list : [...favorites.value, ...list]
      } else if (activeTab.value === 'likes') {
        likes.value = page.value === 1 ? list : [...likes.value, ...list]
      }
      
      hasMore.value = list.length === pageSize.value
    }
  } catch (error) {
    console.error('获取列表失败:', error)
    ElMessage.error('获取列表失败')
  } finally {
    loading.value = false
  }
}

// 标签页切换
const handleTabChange = () => {
  page.value = 1
  hasMore.value = true
  getContentList()
}

// 加载更多
const loadMore = () => {
  page.value++
  getContentList()
}

// 显示编辑对话框
const showEditDialog = () => {
  editDialog.form = {
    avatar: userInfo.value.avatar,
    nickname: userInfo.value.nickname,
    gender: userInfo.value.gender || 0,
    phone: userInfo.value.phone || '',
    bio: userInfo.value.bio
  }
  editDialog.visible = true
}

// 更新个人资料
const handleUpdateProfile = async () => {
  if (!editDialog.form.nickname) {
    ElMessage.warning('请输入昵称')
    return
  }
  
  if (editDialog.form.phone && !/^1[3-9]\d{9}$/.test(editDialog.form.phone)) {
    ElMessage.warning('请输入正确的手机号')
    return
  }
  
  try {
    editDialog.loading = true
    const { data: res } = await request.put('/api/users/profile', {
      avatar: editDialog.form.avatar,
      nickname: editDialog.form.nickname,
      gender: editDialog.form.gender,
      phone: editDialog.form.phone,
      bio: editDialog.form.bio
    })
    
    if (res.code === 200) {
      ElMessage.success('更新成功')
      editDialog.visible = false
      getUserInfo() // 刷新用户信息
    } else {
      ElMessage.error(res.message || '更新失败')
    }
  } catch (error) {
    console.error('更新个人资料失败:', error)
    ElMessage.error('更新失败')
  } finally {
    editDialog.loading = false
  }
}

// 头像上传前检查
const beforeAvatarUpload = (file) => {
  const isImage = file.type.startsWith('image/')
  const isLt2M = file.size / 1024 / 1024 < 2

  if (!isImage) {
    ElMessage.error('只能上传图片文件!')
    return false
  }
  if (!isLt2M) {
    ElMessage.error('图片大小不能超过 2MB!')
    return false
  }
  return true
}

// 头像上传成功
const handleAvatarSuccess = (res) => {
  if (res.code === 200) {
    editDialog.form.avatar = res.data
  } else {
    ElMessage.error(res.message || '上传失败')
  }
}

// 跳转到攻略详情
const goToGuideDetail = (id) => {
  router.push(`/user/guides/${id}`)
}

// 跳转到景点详情
const goToSpotDetail = (id) => {
  router.push(`/spot/${id}`)
}
// 处理图片和视频路径
const getMediaUrl = (path) => {
  if (!path) return ''
  if (path.startsWith('http')) return path
  return `http://localhost:8080${path.startsWith('/') ? '' : '/'}${path}`
}
onMounted(() => {
  getUserInfo()
  getContentList()
})
</script>

<style lang="scss" scoped>
.profile-container {
  max-width: 1200px;
  margin: 20px auto;
  padding: 20px;
  position: relative;
  z-index: 1;

  .profile-header {
    background: #fff;
    border-radius: 12px;
    padding: 32px;
    margin-bottom: 24px;
    box-shadow: 0 2px 12px rgba(0,0,0,0.1);

    .user-info {
      display: flex;
      gap: 24px;
      align-items: flex-start;

      .el-avatar {
        flex-shrink: 0;
        border: 4px solid #fff;
        box-shadow: 0 2px 8px rgba(0,0,0,0.1);
      }

      .info-content {
        flex: 1;

        h2 {
          margin: 0 0 8px;
          font-size: 24px;
          color: #303133;
        }

        .user-id {
          color: #909399;
          margin: 0 0 12px;
          font-size: 14px;
        }

        .bio {
          color: #606266;
          margin: 0 0 16px;
          line-height: 1.6;
        }

        .stats {
          display: flex;
          gap: 32px;
          margin-bottom: 16px;
          padding: 16px 0;
          border-top: 1px solid #ebeef5;
          border-bottom: 1px solid #ebeef5;

          .stat-item {
            text-align: center;

            .count {
              font-size: 20px;
              font-weight: 500;
              color: #303133;
            }

            .label {
              font-size: 14px;
              color: #909399;
              margin-top: 4px;
            }
          }
        }

        .el-button {
          margin-top: 16px;
        }
      }
    }
  }

  .profile-content {
    background: #fff;
    border-radius: 12px;
    padding: 24px;
    box-shadow: 0 2px 12px rgba(0,0,0,0.1);
    min-height: 500px;

    :deep(.el-tabs__header) {
      margin-bottom: 24px;
    }

    .guides-grid,
    .spots-grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
      gap: 24px;
      margin-top: 20px;

      .guide-item,
      .spot-item {
        border-radius: 8px;
        overflow: hidden;
        cursor: pointer;
        transition: all 0.3s ease;
        background: #fff;
        box-shadow: 0 2px 12px rgba(0,0,0,0.1);

        &:hover {
          transform: translateY(-4px);
          box-shadow: 0 4px 16px rgba(0,0,0,0.15);
        }

        .el-image {
          width: 100%;
          height: 200px;
          background-color: #f5f7fa;

          :deep(.image-slot) {
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100%;
            background: #f5f7fa;
            color: #909399;
            font-size: 24px;
          }
        }

        .guide-info,
        .spot-info {
          padding: 16px;

          h3 {
            margin: 0 0 12px;
            font-size: 16px;
            font-weight: 500;
            color: #303133;
            overflow: hidden;
            text-overflow: ellipsis;
            white-space: nowrap;
          }

          .stats {
            display: flex;
            gap: 16px;
            color: #909399;
            font-size: 14px;

            span {
              display: flex;
              align-items: center;
              gap: 4px;

              .el-icon {
                font-size: 16px;
              }
            }
          }

          .price {
            color: #f56c6c;
            font-size: 16px;
            font-weight: 500;
            margin-top: 8px;
          }
        }
      }
    }

    .load-more {
      text-align: center;
      margin-top: 32px;
      padding: 16px 0;

      .el-button {
        font-size: 14px;
      }
    }
  }
}

.avatar-uploader {
  :deep(.el-upload) {
    border: 2px dashed var(--el-border-color);
    border-radius: 8px;
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

:deep(.el-dialog) {
  border-radius: 12px;
  overflow: hidden;

  .el-dialog__header {
    margin: 0;
    padding: 20px 24px;
    border-bottom: 1px solid #ebeef5;
  }

  .el-dialog__body {
    padding: 24px;
  }

  .el-dialog__footer {
    padding: 16px 24px;
    border-top: 1px solid #ebeef5;
  }
}
</style> 
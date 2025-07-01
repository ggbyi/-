<template>
  <div class="guides-container">
    <!-- 顶部操作栏 -->
    <div class="action-bar">
      <div class="search-box">
        <el-input
          v-model="searchQuery"
          placeholder="搜索攻略"
          prefix-icon="Search"
          clearable
          @input="handleSearch"
        />

        <el-select v-model="selectedCategory" placeholder="攻略分类" @change="handleCategoryChange">
          <el-option label="全部" value="" />
          <el-option label="景点玩法" value="spot" />
          <el-option label="美食推荐" value="food" />
          <el-option label="住宿建议" value="hotel" />
          <el-option label="交通指南" value="traffic" />
        </el-select>

        <el-select v-model="sortBy" placeholder="排序方式" @change="handleSortChange">
          <el-option label="最新发布" value="newest" />
          <el-option label="最多收藏" value="favorites" />
          <el-option label="最多点赞" value="likes" />
          <el-option label="最多浏览" value="views" />
        </el-select>
      </div>

      <el-button type="primary" @click="showPublishDialog">
        <el-icon><Edit /></el-icon>
        发布攻略
      </el-button>
    </div>

    <!-- 主要内容区 -->
    <el-row :gutter="20">
      <!-- 左侧攻略列表 -->
      <el-col :span="16">
        <div class="guides-list" v-loading="loading">
          <div v-for="guide in guides" :key="guide.id" class="guide-card" @click="goToDetail(guide.id)">
            <!-- 封面图 -->
            <div class="cover">
              <el-image :src="getMediaUrl(guide.coverUrl)" fit="cover">
                <template #error>
                  <div class="image-error">
                    <el-icon><Picture /></el-icon>
                  </div>
                </template>
              </el-image>
              <div class="category">{{ getCategoryText(guide.category) }}</div>
            </div>

            <!-- 内容区 -->
            <div class="content">
              <h3 class="title">{{ guide.title }}</h3>
              <p class="summary">{{ guide.summary }}</p>

              <!-- 标签 -->
              <div class="tags">
                <el-tag
                  v-for="tag in guide.tags"
                  :key="tag"
                  size="small"
                  effect="plain"
                >
                  {{ tag }}
                </el-tag>
              </div>

              <!-- 作者信息 -->
              <div class="author">
                <div class="info" @click.stop="goToUserProfile(guide.authorId)">
                  <el-avatar :size="32" :src="guide.authorAvatar">
                    {{ guide.authorName?.charAt(0)?.toUpperCase() }}
                  </el-avatar>
                  <span class="name">{{ guide.authorName }}</span>
                </div>

                <div class="stats">
                  <span class="stat-item">
                    <el-icon><View /></el-icon>
                    {{ guide.views }}
                  </span>
                  <span class="stat-item">
                    <el-icon><Star /></el-icon>
                    {{ guide.favorites }}
                  </span>
                  <span class="stat-item">
                    <el-icon><Collection /></el-icon>
                    {{ guide.likes }}
                  </span>
                </div>
              </div>
            </div>

            <!-- 操作区 -->
            <div class="actions">
              <el-button-group>
                <el-button
                  :type="guide.isLiked ? 'primary' : 'default'"
                  @click.stop="handleLike(guide)"
                >
                  <el-icon><Collection /></el-icon>
                  点赞
                </el-button>
              </el-button-group>

              <el-dropdown v-if="guide.isAuthor" trigger="click" @command="handleCommand($event, guide)">
                <el-button>
                  <el-icon><More /></el-icon>
                </el-button>
                <template #dropdown>
                  <el-dropdown-menu>
                    <el-dropdown-item command="edit">编辑</el-dropdown-item>
                    <el-dropdown-item command="delete" divided>删除</el-dropdown-item>
                  </el-dropdown-menu>
                </template>
              </el-dropdown>
            </div>
          </div>

          <!-- 加载更多 -->
          <div class="load-more" v-if="hasMore && !loading">
            <el-button type="primary" text @click="loadMore">
              加载更多 <el-icon class="el-icon--right"><ArrowDown /></el-icon>
            </el-button>
          </div>
        </div>
      </el-col>

      <!-- 右侧推荐区 -->
      <el-col :span="8">
        <!-- 热门攻略 -->
        <el-card class="hot-guides">
          <template #header>
            <div class="card-header">
              <span>热门攻略</span>
              <el-button type="primary" link>更多</el-button>
            </div>
          </template>

          <div class="guide-item" v-for="guide in hotGuides" :key="guide.id" @click="goToDetail(guide.id)">
            <el-image :src="getMediaUrl(guide.coverUrl)" fit="cover" />
            <div class="info">
              <h4>{{ guide.title }}</h4>
              <div class="meta">
                <span class="views">{{ guide.views }}浏览</span>
                <span class="likes">{{ guide.likes }}点赞</span>
              </div>
            </div>
          </div>
        </el-card>

        <!-- 推荐作者 -->
        <el-card class="recommend-authors mt-20">
          <template #header>
            <div class="card-header">
              <span>推荐作者</span>
              <el-button type="primary" link @click="refreshAuthors">换一批</el-button>
            </div>
          </template>

          <div class="author-item" v-for="author in recommendAuthors" :key="author.id">
            <div class="info" @click="goToUserProfile(author.id)">
              <el-avatar :size="40" :src="author.avatar">
                {{ author.nickname?.charAt(0)?.toUpperCase() }}
              </el-avatar>
              <div class="text">
                <h4>{{ author.nickname }}</h4>
                <p>已发布 {{ author.guideCount }} 篇攻略</p>
              </div>
            </div>

            <el-button
                :type="author.isFollowed ? 'default' : 'primary'"
                size="small"
                @click.stop="handleFollow(author)"
            >
              {{ author.isFollowed ? '已关注' : '关注' }}
            </el-button>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 发布/编辑攻略对话框 -->
    <el-dialog
      v-model="guideDialog.visible"
      title="发布攻略"
      width="60%"
      :close-on-click-modal="false"
    >
      <el-form
        :model="guideDialog.form"
        label-width="80px"
        :rules="{
          title: [{ required: true, message: '请输入标题', trigger: 'blur' }],
          category: [{ required: true, message: '请选择分类', trigger: 'change' }],
          content: [{ required: true, message: '请输入内容', trigger: 'blur' }]
        }"
      >
        <el-form-item label="标题" prop="title">
          <el-input v-model="guideDialog.form.title" placeholder="请输入标题" />
        </el-form-item>

        <el-form-item label="分类" prop="category">
          <el-select v-model="guideDialog.form.category" placeholder="请选择分类">
            <el-option label="景点玩法" value="spot" />
            <el-option label="美食推荐" value="food" />
            <el-option label="住宿建议" value="hotel" />
            <el-option label="交通指南" value="traffic" />
          </el-select>
        </el-form-item>

        <el-form-item label="关联景点">
          <el-select
            v-model="guideDialog.form.spotId"
            placeholder="请选择关联景点"
            clearable
            filterable
          >
            <el-option
              v-for="spot in spotList"
              :key="spot.id"
              :label="spot.name"
              :value="spot.id"
            />
          </el-select>
        </el-form-item>

        <el-form-item label="封面图" prop="coverUrl">
          <el-upload
            class="avatar-uploader"
            :action="`${baseURL}/api/file/guide/upload`"
            :headers="uploadHeaders"
            :data="{ type: 'image' }"
            :show-file-list="false"
            :before-upload="beforeCoverUpload"
            :on-success="handleCoverSuccess"
          >
            <img v-if="guideDialog.form.coverUrl" :src="getMediaUrl(guideDialog.form.coverUrl)" class="avatar" />
            <el-icon v-else class="avatar-uploader-icon"><Plus /></el-icon>
          </el-upload>
        </el-form-item>

        <el-form-item label="内容" prop="content">
          <el-input
            v-model="guideDialog.form.content"
            type="textarea"
            :rows="10"
            placeholder="请输入攻略内容"
          />
        </el-form-item>
      </el-form>

      <template #footer>
        <el-button @click="guideDialog.visible = false">取消</el-button>
        <el-button type="primary" @click="handleSubmitGuide" :loading="loading">
          确定
        </el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import {
  Edit,
  More,
  Picture,
  View,
  Star,
  Collection,
  Plus,
  ArrowDown
} from '@element-plus/icons-vue'
import request from '@/utils/request'

const router = useRouter()

// 状态
const loading = ref(false)
const hasMore = ref(true)
const page = ref(1)
const pageSize = ref(10)
const searchQuery = ref('')
const selectedCategory = ref('')
const sortBy = ref('newest')
const guides = ref([])
const hotGuides = ref([])
const recommendAuthors = ref([])
const recommendTags = ref([
  '美食探店', '特色民宿', '交通攻略', '购物指南', '景点推荐',
  '当地特产', '文化体验', '户外活动', '亲子游玩', '拍照打卡'
])

// 对话框状态
const guideDialog = ref({
  visible: false,
  form: {
    title: '',
    category: '',
    coverUrl: '',
    content: '',
    spotId: null
  }
})

const baseURL = 'http://localhost:8080'
const uploadHeaders = {
  Authorization: localStorage.getItem('token')
}

// 景点列表
const spotList = ref([])

// 获取景点列表
const getSpotList = async () => {
  try {
    // 使用已有的景点列表接口
    const { data: res } = await request.get('/api/spots/list', {
      params: {
        page: 1,
        pageSize: 100 // 获取足够多的景点供选择
      }
    })
    if (res.code === 200) {
      // 转换数据格式用于下拉选择
      spotList.value = res.data.records.map(spot => ({
        id: spot.id,
        name: spot.name
      }))
    }
  } catch (error) {
    console.error('获取景点列表失败:', error)
  }
}

// 获取攻略列表
const getGuides = async (isLoadMore = false) => {
  if (loading.value) return

  try {
    loading.value = true
    const params = {
      page: page.value,
      pageSize: pageSize.value,
      keyword: searchQuery.value,
      category: selectedCategory.value,
      sortBy: sortBy.value
    }

    const { data: res } = await request.get('/api/guide', { params })

    if (res.code === 200) {
      if (isLoadMore) {
        guides.value.push(...res.data.records)
      } else {
        guides.value = res.data.records
      }
      hasMore.value = res.data.hasMore
    } else {
      ElMessage.error(res.message || '获取攻略列表失败')
    }
  } catch (error) {
    console.error('获取攻略列表失败:', error)
    ElMessage.error('获取攻略列表失败')
  } finally {
    loading.value = false
  }
}

// 获取热门攻略
const getHotGuides = async () => {
  try {
    const { data: res } = await request.get('/api/guide/hot')
    if (res.code === 200) {
      hotGuides.value = res.data
    }
  } catch (error) {
    console.error('获取热门攻略失败:', error)
  }
}

// 获取推荐作者
const getRecommendAuthors = async () => {
  try {
    const { data: res } = await request.get('/api/guide/authors/recommend')
    if (res.code === 200) {
      recommendAuthors.value = res.data.map(author => ({
        ...author,
        isFollowed: author.isFollowed === 1 // 确保 isFollowed 是布尔值
      }))
    }
  } catch (error) {
    console.error('获取推荐作者失败:', error)
  }
}

// 搜索处理
const handleSearch = () => {
  page.value = 1
  getGuides()
}

// 分类切换
const handleCategoryChange = () => {
  page.value = 1
  getGuides()
}

// 排序切换
const handleSortChange = () => {
  page.value = 1
  getGuides()
}

// 加载更多
const loadMore = () => {
  page.value++
  getGuides(true)
}

// 点赞
const handleLike = async (guide) => {
  try {
    const { data: res } = await request.post(`/api/guide/${guide.id}/like`)
    if (res.code === 200) {
      guide.isLiked = !guide.isLiked
      guide.likes += guide.isLiked ? 1 : -1
      ElMessage.success(guide.isLiked ? '点赞成功' : '已取消点赞')
    }
  } catch (error) {
    console.error('操作失败:', error)
    ElMessage.error('操作失败')
  }
}

// 收藏
const handleFavorite = async (guide) => {
  try {
    const { data: res } = await request.post(`/api/guide/${guide.id}/favorite`)
    if (res.code === 200) {
      guide.isFavorited = !guide.isFavorited
      guide.favorites += guide.isFavorited ? 1 : -1
      ElMessage.success(guide.isFavorited ? '收藏成功' : '已取消收藏')
    }
  } catch (error) {
    console.error('操作失败:', error)
    ElMessage.error('操作失败')
  }
}

// 关注作者
const handleFollow = async (author) => {
  try {
    const { data: res } = await request.post(`/api/user/follow/${author.id}`)
    if (res.code === 200) {
      author.isFollowed = !author.isFollowed
      ElMessage.success(author.isFollowed ? '关注成功' : '已取消关注')
    }
  } catch (error) {
    console.error('操作失败:', error)
    ElMessage.error('操作失败')
  }
}

// 刷新推荐作者
const refreshAuthors = () => {
  getRecommendAuthors()
}

// 显示发布对话框
const showPublishDialog = () => {
  // 检查登录状态
  const token = localStorage.getItem('token')
  if (!token) {
    ElMessage.warning('请先登录')
    router.push('/login')
    return
  }

  // 获取景点列表
  getSpotList()

  // 重置表单
  guideDialog.value.form = {
    title: '',
    category: '',
    coverUrl: '',
    content: '',
    spotId: null
  }
  guideDialog.value.visible = true
}

// 封面上传前检查
const beforeCoverUpload = (file) => {
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

// 封面上传成功
const handleCoverSuccess = (res) => {
  if (res.code === 200) {
    guideDialog.value.form.coverUrl = res.data
    ElMessage.success('上传成功')
  } else {
    ElMessage.error(res.message || '上传失败')
  }
}

// 提交攻略
const handleSubmitGuide = async () => {
  // 表单验证
  if (!guideDialog.value.form.title) {
    ElMessage.warning('请输入标题')
    return
  }
  if (!guideDialog.value.form.category) {
    ElMessage.warning('请选择分类')
    return
  }
  if (!guideDialog.value.form.coverUrl) {
    ElMessage.warning('请上传封面图')
    return
  }
  if (!guideDialog.value.form.content) {
    ElMessage.warning('请输入内容')
    return
  }

  try {
    loading.value = true
    const { data: res } = await request({
      url: '/api/guide',
      method: 'post',
      data: {
        title: guideDialog.value.form.title,
        category: guideDialog.value.form.category,
        coverUrl: guideDialog.value.form.coverUrl,
        content: guideDialog.value.form.content,
        spotId: guideDialog.value.form.spotId || null
      }
    })

    if (res.code === 200) {
      ElMessage.success('发布成功')
      guideDialog.value.visible = false
      // 重置表单
      guideDialog.value.form = {
        title: '',
        category: '',
        coverUrl: '',
        content: '',
        spotId: null
      }
      // 刷新列表
      page.value = 1
      getGuides()
    } else {
      ElMessage.error(res.message || '发布失败')
    }
  } catch (error) {
    console.error('发布失败:', error)
    ElMessage.error('发布失败')
  } finally {
    loading.value = false
  }
}

// 跳转到详情页
const goToDetail = (id) => {
  router.push(`/user/guides/${id}`)
}

// 跳转到用户主页
const goToUserProfile = (id) => {
  router.push(`/user/${id}`)
}

// 获取分类文本
const getCategoryText = (category) => {
  const map = {
    spot: '景点玩法',
    food: '美食推荐',
    hotel: '住宿建议',
    traffic: '交通指南'
  }
  return map[category] || category
}

// 处理图片和视频路径
const getMediaUrl = (path) => {
  if (!path) return ''
  if (path.startsWith('http')) return path
  return `http://localhost:8080${path.startsWith('/') ? '' : '/'}${path}`
}

onMounted(() => {
  getGuides()
  getHotGuides()
  getRecommendAuthors()
})
</script>

<style lang="scss" scoped>
.guides-container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 20px;
  
  .action-bar {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 24px;
    background: linear-gradient(135deg, rgba(255,255,255,0.9) 0%, rgba(240,245,255,0.9) 100%);
    padding: 16px 20px;
    border-radius: 12px;
    box-shadow: 0 4px 12px rgba(0,0,0,0.05);
    
    .search-box {
      display: flex;
      gap: 16px;
      flex-wrap: wrap;
      
      .el-input {
        width: 260px;
      }
      
      .el-select {
        width: 140px;
      }
    }
    
    .el-button {
      padding: 10px 20px;
      border-radius: 8px;
      transition: all 0.3s;
      
      &:hover {
        transform: translateY(-2px);
        box-shadow: 0 4px 12px rgba(64, 158, 255, 0.2);
      }
    }
  }
  
  .guides-list {
    .guide-card {
      background: #fff;
      border-radius: 12px;
      overflow: hidden;
      margin-bottom: 20px;
      box-shadow: 0 4px 12px rgba(0,0,0,0.05);
      transition: transform 0.3s, box-shadow 0.3s;
      cursor: pointer;
      
      &:hover {
        transform: translateY(-5px);
        box-shadow: 0 8px 20px rgba(0,0,0,0.1);
      }
      
      .cover {
        position: relative;
        height: 220px;
        
        .el-image {
          width: 100%;
          height: 100%;
        }
        
        .category {
          position: absolute;
          top: 12px;
          left: 12px;
          padding: 5px 10px;
          background: rgba(0,0,0,0.6);
          color: #fff;
          border-radius: 20px;
          font-size: 13px;
        }
      }
      
      .content {
        padding: 20px;
        
        .title {
          margin: 0 0 12px;
          font-size: 18px;
          font-weight: 600;
          
          &:hover {
            color: var(--el-color-primary);
          }
        }
        
        .summary {
          margin: 0 0 16px;
          color: #606266;
          line-height: 1.6;
          display: -webkit-box;
          -webkit-line-clamp: 2;
          -webkit-box-orient: vertical;
          overflow: hidden;
        }
        
        .tags {
          display: flex;
          flex-wrap: wrap;
          gap: 8px;
          margin-bottom: 16px;
          
          .el-tag {
            border-radius: 16px;
          }
        }
        
        .author {
          display: flex;
          justify-content: space-between;
          align-items: center;
          
          .info {
            display: flex;
            align-items: center;
            gap: 8px;
            
            .name {
              font-size: 14px;
              font-weight: 500;
            }
          }
          
          .stats {
            display: flex;
            gap: 16px;
            
            .stat-item {
              display: flex;
              align-items: center;
              gap: 4px;
              color: #909399;
              font-size: 13px;
            }
          }
        }
      }
      
      .actions {
        display: flex;
        justify-content: space-between;
        align-items: center;
        padding: 12px 20px;
        border-top: 1px solid #ebeef5;
        background-color: #f9f9f9;
      }
    }
    
    .load-more {
      text-align: center;
      margin: 20px 0;
    }
  }
  
  .hot-guides {
    border-radius: 12px;
    overflow: hidden;
    box-shadow: 0 4px 12px rgba(0,0,0,0.05);
    
    .card-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      
      span {
        font-size: 16px;
        font-weight: 600;
        position: relative;
        padding-left: 10px;
        
        &::before {
          content: '';
          position: absolute;
          left: 0;
          top: 2px;
          height: 16px;
          width: 3px;
          background: var(--el-color-primary);
          border-radius: 3px;
        }
      }
    }
    
    .guide-item {
      display: flex;
      gap: 12px;
      padding: 12px 0;
      cursor: pointer;
      transition: all 0.2s;
      
      &:hover {
        transform: translateX(5px);
      }
      
      &:not(:last-child) {
        border-bottom: 1px solid #ebeef5;
      }
      
      .el-image {
        width: 100px;
        height: 70px;
        border-radius: 8px;
        flex-shrink: 0;
      }
      
      .info {
        flex: 1;
        overflow: hidden;
        
        h4 {
          margin: 0 0 8px;
          font-size: 15px;
          white-space: nowrap;
          overflow: hidden;
          text-overflow: ellipsis;
          
          &:hover {
            color: var(--el-color-primary);
          }
        }
        
        .meta {
          display: flex;
          gap: 12px;
          color: #909399;
          font-size: 13px;
        }
      }
    }
  }
  
  .recommend-authors {
    border-radius: 12px;
    overflow: hidden;
    box-shadow: 0 4px 12px rgba(0,0,0,0.05);
    
    .author-item {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 12px 0;
      
      &:not(:last-child) {
        border-bottom: 1px solid #ebeef5;
      }
      
      .info {
        display: flex;
        align-items: center;
        gap: 12px;
        cursor: pointer;
        
        .text {
          h4 {
            margin: 0 0 4px;
            font-size: 15px;
          }
          
          p {
            margin: 0;
            color: #909399;
            font-size: 13px;
          }
        }
      }
      
      .el-button {
        border-radius: 20px;
      }
    }
  }
}

.mt-20 {
  margin-top: 20px;
}
</style> 
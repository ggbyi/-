<template>
  <div class="explore-container">
    <div class="content-layout">
      <!-- 左侧边栏：搜索和分类 -->
      <div class="sidebar">
        <div class="sidebar-sticky">
          <div class="sidebar-header">
            <h2>探索发现</h2>
            <p>寻找你的下一个目的地</p>
          </div>
          
          <!-- 搜索框 -->
          <div class="search-section">
            <el-input
              v-model="searchQuery"
              placeholder="搜索景点、城市..."
              clearable
              @keyup.enter="handleSearch"
              class="search-input"
            >
              <template #prefix>
                <el-icon><Search /></el-icon>
              </template>
              <template #suffix>
                <el-button 
                  v-if="searchQuery" 
                  circle 
                  class="search-btn"
                  @click="handleSearch"
                >
                  <el-icon><ArrowRight /></el-icon>
                </el-button>
              </template>
            </el-input>
          </div>
          
          <!-- 分类列表 -->
          <div class="category-section">
            <h3>目的地分类</h3>
            <div class="category-list">
              <div
                v-for="category in categories"
                :key="category.id"
                :class="['category-item', { active: selectedCategory === category.id }]"
                @click="handleCategoryChange(category.id)"
              >
                <div class="category-icon">
                  <el-icon v-if="category.id === ''"><Compass /></el-icon>
                  <el-icon v-else-if="category.id === '1'"><Sunny /></el-icon>
                  <el-icon v-else-if="category.id === '2'"><Place /></el-icon>
                  <el-icon v-else-if="category.id === '3'"><Mug /></el-icon>
                  <el-icon v-else-if="category.id === '4'"><Opportunity /></el-icon>
                  <el-icon v-else><Aim /></el-icon>
                </div>
                <span>{{ category.name }}</span>
                <div class="arrow-icon">
                  <el-icon><ArrowRight /></el-icon>
                </div>
              </div>
            </div>
          </div>
          
          <!-- 热门标签 -->
          <div class="tags-section">
            <h3>热门标签</h3>
            <div class="tags-cloud">
              <el-tag
                v-for="tag in popularTags"
                :key="tag"
                :type="getRandomTagType()"
                effect="light"
                class="tag-item"
                @click="applyTag(tag)"
              >
                {{ tag }}
              </el-tag>
            </div>
          </div>
        </div>
      </div>
      
      <!-- 右侧内容区：景点瀑布流 -->
      <div class="main-content">
        <!-- 顶部过滤栏 -->
        <div class="filter-bar">
          <div class="result-info">
            {{ spots.length > 0 ? `${spots.length}个相关结果` : '正在加载...' }}
          </div>
          <div class="view-options">
            <span :class="['view-option', { active: viewMode === 'grid' }]" @click="viewMode = 'grid'">
              <el-icon><Grid /></el-icon> 网格
            </span>
            <span :class="['view-option', { active: viewMode === 'waterfall' }]" @click="viewMode = 'waterfall'">
              <el-icon><Menu /></el-icon> 瀑布流
            </span>
          </div>
        </div>
        
        <!-- 景点列表展示 -->
        <el-empty v-if="!loading && spots.length === 0" description="暂无数据" />
        
        <div 
          v-else 
          :class="['spots-display', viewMode === 'grid' ? 'grid-mode' : 'waterfall-mode']"
          v-loading="loading"
        >
          <div
            v-for="(spot, index) in spots"
            :key="spot.id"
            :class="['spot-card', `card-size-${getCardSize(index)}`]"
            @click="goToDetail(spot.id)"
          >
            <!-- 媒体内容 -->
            <div class="card-media">
              <video
                v-if="spot.videoUrl && isValidVideo(spot.videoUrl)"
                class="media-content video"
                :src="getMediaUrl(spot.videoUrl)"
                loop
                muted
                @mouseover="playVideo"
                @mouseout="pauseVideo"
              />
              <el-image
                v-else
                class="media-content image"
                :src="getMediaUrl(spot.coverUrl || spot.images?.split(',')[0])"
                fit="cover"
                :preview-src-list="getPreviewImages(spot)"
                loading="lazy"
              >
                <template #error>
                  <div class="image-error">
                    <el-icon><Picture /></el-icon>
                  </div>
                </template>
              </el-image>
              
              <!-- 景点标签 -->
              <div class="spot-tag">{{ getCategoryName(spot.categoryId) }}</div>
              
              <!-- 收藏按钮 -->
              <div class="like-btn" @click.stop="toggleLike(spot)">
                <el-icon :class="{ active: spot.isLiked }"><Collection /></el-icon>
              </div>
            </div>
            
            <!-- 内容信息 -->
            <div class="card-content">
              <h3 class="spot-title">{{ spot.name }}</h3>
              <p class="spot-desc">{{ spot.description }}</p>
              
              <!-- 底部信息栏 -->
              <div class="card-footer">
                <div class="user-info">
                  <el-avatar :size="24" :src="spot.creatorAvatar">
                    <el-icon><User /></el-icon>
                  </el-avatar>
                  <span>{{ spot.creatorName }}</span>
                </div>
                <div class="stats">
                  <span class="like-count">
                    <el-icon><Star /></el-icon> {{ spot.likeCount }}
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>
        
        <!-- 加载更多 -->
        <div v-if="hasMore && !loading" class="load-more" @click="loadMore">
          <span>加载更多精彩内容</span>
          <el-icon><ArrowDown /></el-icon>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted, computed } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import {
  Search, ArrowDown, Picture, ArrowRight,
  User, Star, Collection, Compass, Menu,
  Grid, Sunny, Place, Mug, Opportunity, Aim
} from '@element-plus/icons-vue'
import request from '@/utils/request'

// 路由实例
const router = useRouter()

// 响应式状态
const searchQuery = ref('')
const selectedCategory = ref('')
const categories = ref([])
const spots = ref([])
const loading = ref(false)
const hasMore = ref(true)
const page = ref(1)
const pageSize = ref(20)
const viewMode = ref('waterfall') // 'grid' or 'waterfall'
const myCanvas = ref(null)

// 热门标签 - 可以从后端获取或者静态定义
const popularTags = ref([
  '海滩', '山脉', '古镇', '美食', '博物馆', 
  '徒步', '温泉', '购物', '摄影', '文化'
])

// 随机获取标签类型，增加视觉多样性
const getRandomTagType = () => {
  const types = ['', 'success', 'warning', 'info']
  return types[Math.floor(Math.random() * types.length)]
}

// 应用标签筛选
const applyTag = (tag) => {
  searchQuery.value = tag
  handleSearch()
}

// 根据索引获取不同的卡片尺寸，增加视觉变化
const getCardSize = (index) => {
  if (viewMode.value === 'grid') return 'normal'
  
  const pattern = index % 5
  if (pattern === 0) return 'large'
  if (pattern === 3) return 'wide'
  return 'normal'
}

// 获取分类名称
const getCategoryName = (categoryId) => {
  if (!categoryId) return '推荐'
  const category = categories.value.find(c => c.id === categoryId)
  return category ? category.name : '未分类'
}

// 获取分类列表
const getCategories = async () => {
  try {
    const { data: res } = await request.get('/api/spot/category/list')
    if (res.code === 200) {
      categories.value = [
        { id: '', name: '全部' },
        ...res.data
      ]
    }
  } catch (error) {
    console.error('获取分类失败:', error)
    ElMessage.error('获取分类列表失败')
  }
}

// 获取景点列表
const getSpots = async (isLoadMore = false) => {
  if (loading.value) return

  try {
    loading.value = true
    const params = {
      page: page.value,
      pageSize: pageSize.value,
      keyword: searchQuery.value,
      categoryId: selectedCategory.value
    }

    const { data: res } = await request.get('/api/spots/list', { params })

    if (res.code === 200) {
      if (isLoadMore) {
        spots.value.push(...res.data.records)
      } else {
        spots.value = res.data.records
      }
      hasMore.value = res.data.hasMore
    }
  } catch (error) {
    console.error('获取列表失败:', error)
    ElMessage.error('获取景点列表失败')
  } finally {
    loading.value = false
  }
}

// 处理搜索
const handleSearch = () => {
  page.value = 1
  getSpots()
}

// 处理分类切换
const handleCategoryChange = (categoryId) => {
  selectedCategory.value = categoryId
  page.value = 1
  getSpots()
}

// 视频控制
const playVideo = (e) => {
  if (e.target.paused) {
    e.target.play().catch(() => {})
  }
}

const pauseVideo = (e) => {
  if (!e.target.paused) {
    e.target.pause()
  }
}

// 处理图片和视频路径
const getMediaUrl = (path) => {
  if (!path) return ''
  if (path.startsWith('http')) return path
  return `http://localhost:8080${path.startsWith('/') ? '' : '/'}${path}`
}

// 处理点赞
const toggleLike = async (spot) => {
  try {
    const { data: res } = await request.post(`/api/spots/${spot.id}/like`)
    if (res.code === 200) {
      spot.isLiked = !spot.isLiked
      spot.likeCount += spot.isLiked ? 1 : -1
      ElMessage.success(spot.isLiked ? '收藏成功' : '已取消收藏')
    }
  } catch (error) {
    console.error('操作失败:', error)
    ElMessage.error('操作失败，请稍后重试')
  }
}

// 加载更多
const loadMore = () => {
  if (!loading.value && hasMore.value) {
    page.value++
    getSpots(true)
  }
}

// 跳转详情
const goToDetail = (id) => {
  // 确保所有视频暂停
  document.querySelectorAll('video').forEach(video => {
    if (!video.paused) {
      video.pause();
    }
  });

  // 路由跳转
  router.push(`/spot/${id}`);
}

// 检查视频URL是否有效
const isValidVideo = (url) => {
  return url && (url.endsWith('.mp4') || url.endsWith('.webm'))
}

// 获取预览图片列表
const getPreviewImages = (spot) => {
  if (!spot.images) return []
  return spot.images.split(',').map(img => getMediaUrl(img))
}

// 生命周期钩子
onMounted(() => {
  getCategories()
  getSpots()
})

// 清理工作
onUnmounted(() => {
  spots.value = []
})
</script>

<style lang="scss" scoped>
@use '@/styles/mixins.scss' as *;

.explore-container {
  background: #f8f9fa;
  min-height: 100vh;
  
  .content-layout {
    display: flex;
    margin: 0 auto;
    max-width: 1600px;
    position: relative;
    
    // 左侧边栏
    .sidebar {
      width: 280px;
      padding: 20px;
      
      .sidebar-sticky {
        position: sticky;
        top: 20px;
        background: white;
        border-radius: 16px;
        box-shadow: 0 4px 20px rgba(0, 0, 0, 0.08);
        padding: 25px;
        transition: all 0.3s;
        
        &:hover {
          box-shadow: 0 6px 30px rgba(0, 0, 0, 0.12);
        }
        
        .sidebar-header {
          margin-bottom: 25px;
          border-bottom: 1px solid #eee;
          padding-bottom: 20px;
          
          h2 {
            font-size: 24px;
            color: #333;
            margin: 0 0 8px 0;
            background: linear-gradient(45deg, #ff4757, #ff6b81);
            -webkit-background-clip: text;
            background-clip: text;
            -webkit-text-fill-color: transparent;
          }
          
          p {
            color: #666;
            margin: 0;
            font-size: 14px;
          }
        }
        
        // 搜索区域
        .search-section {
          margin-bottom: 25px;
          
          .search-input {
            border-radius: 12px;
            overflow: hidden;
            
            :deep(.el-input__wrapper) {
              border-radius: 12px;
              padding-right: 8px;
              box-shadow: 0 2px 12px rgba(0, 0, 0, 0.05);
              
              &:hover {
                box-shadow: 0 4px 15px rgba(0, 0, 0, 0.08);
              }
            }
            
            :deep(.el-input__prefix) {
              margin-right: 8px;
              color: #ff4757;
            }
            
            .search-btn {
              background: linear-gradient(45deg, #ff4757, #ff6b81);
              color: white;
              border: none;
              margin-left: 5px;
              
              &:hover {
                transform: scale(1.05);
              }
            }
          }
        }
        
        // 分类区域
        .category-section {
          margin-bottom: 25px;
          
          h3 {
            font-size: 16px;
            color: #333;
            margin-bottom: 15px;
            display: flex;
            align-items: center;
            
            &:before {
              content: '';
              display: inline-block;
              width: 4px;
              height: 16px;
              background: #ff4757;
              margin-right: 8px;
              border-radius: 2px;
            }
          }
          
          .category-list {
            display: flex;
            flex-direction: column;
            gap: 8px;
            
            .category-item {
              display: flex;
              align-items: center;
              padding: 12px 15px;
              border-radius: 12px;
              cursor: pointer;
              transition: all 0.3s;
              
              .category-icon {
                color: #666;
                margin-right: 12px;
                font-size: 18px;
                transition: all 0.3s;
              }
              
              span {
                flex: 1;
                color: #333;
              }
              
              .arrow-icon {
                color: #ccc;
                font-size: 14px;
                transition: all 0.3s;
                opacity: 0;
                transform: translateX(-10px);
              }
              
              &:hover {
                background: #f8f9fa;
                
                .category-icon {
                  color: #ff4757;
                  transform: scale(1.1);
                }
                
                .arrow-icon {
                  opacity: 1;
                  transform: translateX(0);
                }
              }
              
              &.active {
                background: rgba(255, 71, 87, 0.1);
                
                .category-icon, span {
                  color: #ff4757;
                  font-weight: 500;
                }
                
                .arrow-icon {
                  opacity: 1;
                  transform: translateX(0);
                  color: #ff4757;
                }
              }
            }
          }
        }
        
        // 标签区域
        .tags-section {
          h3 {
            font-size: 16px;
            color: #333;
            margin-bottom: 15px;
            display: flex;
            align-items: center;
            
            &:before {
              content: '';
              display: inline-block;
              width: 4px;
              height: 16px;
              background: #ff4757;
              margin-right: 8px;
              border-radius: 2px;
            }
          }
          
          .tags-cloud {
            display: flex;
            flex-wrap: wrap;
            gap: 10px;
            
            .tag-item {
              cursor: pointer;
              transition: all 0.3s;
              border-radius: 20px;
              
              &:hover {
                transform: translateY(-2px);
                box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
              }
            }
          }
        }
      }
    }
    
    // 右侧主内容
    .main-content {
      flex: 1;
      padding: 20px;
      
      .filter-bar {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 20px;
        background: white;
        padding: 15px 20px;
        border-radius: 12px;
        box-shadow: 0 2px 10px rgba(0, 0, 0, 0.05);
        
        .result-info {
          color: #666;
          font-size: 14px;
        }
        
        .view-options {
          display: flex;
          gap: 15px;
          
          .view-option {
            display: flex;
            align-items: center;
            gap: 5px;
            color: #666;
            cursor: pointer;
            padding: 6px 10px;
            border-radius: 6px;
            transition: all 0.3s;
            
            &:hover {
              background: #f8f9fa;
            }
            
            &.active {
              color: #ff4757;
              background: rgba(255, 71, 87, 0.1);
            }
          }
        }
      }
      
      // 景点展示区
      .spots-display {
        margin-bottom: 30px;
        
        // 网格布局模式
        &.grid-mode {
          display: grid;
          grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
          gap: 20px;
          
          .spot-card {
            height: 100%;
            
            .card-media {
              height: 220px;
            }
          }
        }
        
        // 瀑布流布局模式
        &.waterfall-mode {
          column-count: 1;
          column-gap: 20px;
          
          @media (min-width: 768px) {
            column-count: 2;
          }
          
          @media (min-width: 1200px) {
            column-count: 3;
          }
          
          @media (min-width: 1600px) {
            column-count: 4;
          }
          
          .spot-card {
            break-inside: avoid;
            margin-bottom: 20px;
            
            &.card-size-large {
              .card-media {
                height: 360px;
              }
            }
            
            &.card-size-wide {
              .card-media {
                height: 260px;
              }
            }
            
            &.card-size-normal {
              .card-media {
                height: 280px;
              }
            }
          }
        }
        
        // 景点卡片通用样式
        .spot-card {
          background: white;
          border-radius: 16px;
          overflow: hidden;
          box-shadow: 0 4px 15px rgba(0, 0, 0, 0.08);
          cursor: pointer;
          transition: all 0.3s cubic-bezier(0.25, 0.8, 0.25, 1);
          transform: translateY(0);
          position: relative;
          
          &:hover {
            transform: translateY(-5px);
            box-shadow: 0 15px 30px rgba(0, 0, 0, 0.15);
            
            .card-media {
              .media-content {
                transform: scale(1.05);
              }
              
              &:after {
                opacity: 0.5;
              }
              
              .spot-tag {
                transform: translateY(-5px);
              }
              
              .like-btn {
                opacity: 1;
                transform: translateY(0);
              }
            }
          }
          
          .card-media {
            position: relative;
            overflow: hidden;
            
            &:after {
              content: "";
              position: absolute;
              top: 0;
              left: 0;
              width: 100%;
              height: 100%;
              background: linear-gradient(to bottom, rgba(0,0,0,0), rgba(0,0,0,0.6));
              opacity: 0.3;
              transition: opacity 0.3s;
              z-index: 1;
            }
            
            .media-content {
              width: 100%;
              height: 100%;
              object-fit: cover;
              transition: transform 0.5s;
            }
            
            .spot-tag {
              position: absolute;
              top: 15px;
              left: 15px;
              padding: 6px 12px;
              background: rgba(255, 71, 87, 0.8);
              color: white;
              border-radius: 20px;
              font-size: 12px;
              z-index: 2;
              transition: transform 0.3s;
            }
            
            .like-btn {
              position: absolute;
              bottom: 15px;
              right: 15px;
              background: rgba(255, 255, 255, 0.9);
              width: 36px;
              height: 36px;
              border-radius: 50%;
              display: flex;
              align-items: center;
              justify-content: center;
              color: #666;
              font-size: 18px;
              cursor: pointer;
              z-index: 2;
              opacity: 0;
              transform: translateY(10px);
              transition: all 0.3s;
              
              &:hover {
                background: white;
                transform: scale(1.1) translateY(0) !important;
              }
              
              .el-icon.active {
                color: #ff4757;
              }
            }
          }
          
          .card-content {
            padding: 20px;
            
            .spot-title {
              font-size: 18px;
              color: #333;
              margin: 0 0 10px 0;
              line-height: 1.3;
            }
            
            .spot-desc {
              color: #666;
              font-size: 14px;
              line-height: 1.5;
              margin-bottom: 15px;
              @include text-overflow(3);
            }
            
            .card-footer {
              display: flex;
              justify-content: space-between;
              align-items: center;
              border-top: 1px solid #f0f0f0;
              padding-top: 15px;
              
              .user-info {
                display: flex;
                align-items: center;
                gap: 8px;
                color: #666;
                font-size: 13px;
              }
              
              .stats {
                .like-count {
                  display: flex;
                  align-items: center;
                  gap: 5px;
                  color: #666;
                  font-size: 13px;
                  
                  .el-icon {
                    color: #ff9800;
                  }
                }
              }
            }
          }
        }
      }
      
      // 加载更多按钮
      .load-more {
        background: linear-gradient(45deg, #ff4757, #ff6b81);
        color: white;
        padding: 15px 30px;
        border-radius: 30px;
        text-align: center;
        cursor: pointer;
        margin: 20px auto;
        width: fit-content;
        display: flex;
        align-items: center;
        gap: 10px;
        box-shadow: 0 5px 15px rgba(255, 71, 87, 0.3);
        transition: all 0.3s;
        
        &:hover {
          transform: translateY(-3px);
          box-shadow: 0 8px 20px rgba(255, 71, 87, 0.4);
        }
        
        &:active {
          transform: translateY(-1px);
        }
      }
    }
  }
}

// 自定义el-tag样式
:deep(.el-tag) {
  border-radius: 20px;
  padding: 0 12px;
}

// 动画效果
@keyframes fadeIn {
  from {
    opacity: 0;
    transform: translateY(10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.spots-display {
  animation: fadeIn 0.5s ease-out;
}

// 响应式调整
@media (max-width: 992px) {
  .explore-container {
    .content-layout {
      flex-direction: column;
      
      .sidebar {
        width: 100%;
        margin-bottom: 20px;
        
        .sidebar-sticky {
          position: relative;
          top: 0;
        }
      }
    }
  }
}
</style>
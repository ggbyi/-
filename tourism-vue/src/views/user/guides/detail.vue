<template>
  <div class="guide-detail">
    <!-- 返回按钮 -->
    <div class="back-btn" @click="$router.back()">
      <el-icon><ArrowLeft /></el-icon>
    </div>

    <!-- 封面图 -->
    <div class="cover-section">
      <el-image
        :src="getMediaUrl(guide.coverUrl)"
        fit="cover"
        class="cover-image"
      />
      <div class="cover-info">
        <h1>{{ guide.title }}</h1>
        <div class="meta-info">
          <span class="category">{{ getCategoryLabel(guide.category) }}</span>
          <span class="time">{{ formatTime(guide.createdTime) }}</span>
          <span class="views">
            <el-icon><View /></el-icon>
            {{ guide.views }}
          </span>
        </div>
      </div>
    </div>

    <!-- 主要内容 -->
    <div class="main-content">
      <div class="content-wrapper">
        <!-- 作者信息 -->
        <div class="author-info">
          <el-avatar :size="40" :src="getMediaUrl(guide.authorAvatar)">
            {{ guide.authorName?.charAt(0)?.toUpperCase() }}
          </el-avatar>
          <div class="author-meta">
            <div class="name">{{ guide.authorName }}</div>
            <div class="bio">{{ guide.authorBio || '暂无简介' }}</div>
          </div>
        </div>

        <!-- 攻略内容 -->
        <div class="guide-content" v-html="renderContent(guide.content)" />

        <!-- 关联景点 -->
        <div v-if="guide.spotId" class="related-spot">
          <h3>相关景点</h3>
          <div class="spot-card" @click="goToSpot(guide.spotId)">
            <el-image
              :src="getMediaUrl(guide.coverUrl)"
              fit="cover"
              class="spot-image"
            />
            <div class="spot-info">
              <div class="name">{{ guide.spotName }}</div>
              <div class="desc">{{ guide.spotDesc }}</div>
            </div>
          </div>
        </div>

        <!-- 操作按钮 -->
        <div class="action-bar">
          <el-button
            :type="guide.isLiked ? 'primary' : 'default'"
            @click="handleLike"
          >
            <el-icon><Star /></el-icon>
            {{ guide.likeCount || 0 }}
          </el-button>
        </div>

        <!-- 评论区 -->
        <div class="comment-section">
          <h3>评论 ({{ guide.commentCount || 0 }})</h3>
          
          <!-- 评论输入框 -->
          <div class="comment-input">
            <el-input
              v-model="commentContent"
              type="textarea"
              :rows="3"
              placeholder="写下你的评论..."
            />
            <el-button
              type="primary"
              :disabled="!commentContent.trim()"
              @click="submitComment"
            >
              发表评论
            </el-button>
          </div>

          <!-- 评论列表 -->
          <div class="comment-list">
            <div
              v-for="comment in comments"
              :key="comment.id"
              class="comment-item"
            >
              <el-avatar :size="32" :src="comment.userAvatar" />
              <div class="comment-content">
                <div class="comment-header">
                  <span class="username">{{ comment.userName }}</span>
                  <span class="time">{{ formatTime(comment.createdTime) }}</span>
                </div>
                <div class="comment-text">{{ comment.content }}</div>
              </div>
            </div>
          </div>

          <!-- 加载更多评论 -->
          <div
            v-if="hasMoreComments"
            class="load-more"
            @click="loadMoreComments"
          >
            <el-icon><ArrowDown /></el-icon>
            <span>加载更多评论</span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { ArrowLeft, View, Star, ArrowDown } from '@element-plus/icons-vue'
import request from '@/utils/request'
import { formatTime } from '@/utils'

const route = useRoute()
const router = useRouter()

// 状态数据
const guide = ref({})
const comments = ref([])
const commentContent = ref('')
const commentPage = ref(1)
const commentSize = ref(10)
const hasMoreComments = ref(true)
const loading = ref(false)

// 分类选项
const categories = [
  { label: '景点玩法', value: 'spot' },
  { label: '美食推荐', value: 'food' },
  { label: '住宿建议', value: 'hotel' },
  { label: '交通指南', value: 'traffic' }
]

// 获取攻略详情
const getGuideDetail = async () => {
  try {
    loading.value = true
    const { data: res } = await request.get(`/api/guide/${route.params.id}`)
    if (res.code === 200) {
      guide.value = res.data
    }
  } catch (error) {
    console.error('获取攻略详情失败:', error)
    ElMessage.error('获取攻略详情失败')
  } finally {
    loading.value = false
  }
}

// 获取评论列表
const getComments = async (isLoadMore = false) => {
  try {
    const { data: res } = await request.get(`/api/guide/${route.params.id}/comments`, {
      params: {
        page: commentPage.value,
        size: commentSize.value
      }
    })
    
    if (res.code === 200) {
      if (isLoadMore) {
        comments.value.push(...res.data.records)
      } else {
        comments.value = res.data.records
      }
      hasMoreComments.value = res.data.hasMore
    }
  } catch (error) {
    console.error('获取评论失败:', error)
    ElMessage.error('获取评论失败')
  }
}

// 提交评论
const submitComment = async () => {
  if (!commentContent.value.trim()) return
  
  try {
    const { data: res } = await request.post(`/api/guide/${route.params.id}/comments`, {
      content: commentContent.value
    })
    
    if (res.code === 200) {
      ElMessage.success('评论成功')
      commentContent.value = ''
      commentPage.value = 1
      getComments()
      guide.value.commentCount++
    }
  } catch (error) {
    console.error('评论失败:', error)
    ElMessage.error('评论失败')
  }
}

// 加载更多评论
const loadMoreComments = () => {
  if (loading.value || !hasMoreComments.value) return
  commentPage.value++
  getComments(true)
}

// 处理点赞
const handleLike = async () => {
  try {
    const { data: res } = await request.post(`/api/guide/${guide.value.id}/like`)
    if (res.code === 200) {
      guide.value.isLiked = !guide.value.isLiked
      guide.value.likeCount = guide.value.isLiked 
        ? (guide.value.likeCount || 0) + 1 
        : (guide.value.likeCount || 1) - 1
      ElMessage.success(guide.value.isLiked ? '点赞成功' : '已取消点赞')
    }
  } catch (error) {
    console.error('操作失败:', error)
    ElMessage.error('操作失败')
  }
}

// 跳转到景点详情
const goToSpot = (id) => {
  router.push(`/spot/${id}`)
}

// 获取分类标签
const getCategoryLabel = (value) => {
  const category = categories.find(item => item.value === value)
  return category ? category.label : value
}

// 获取媒体URL
const getMediaUrl = (url) => {
  if (!url) return ''
  if (url.startsWith('http')) return url
  return `http://localhost:8080${url.startsWith('/') ? '' : '/'}${url}`
}

// 暂时使用简单的文本渲染，不使用 markdown-it
const renderContent = (content) => {
  if (!content) return ''
  // 将文本按行分割，每行包装在 p 标签中
  return content.split('\n')
    .filter(line => line.trim()) // 过滤空行
    .map(line => `<p>${line}</p>`)
    .join('')
}

onMounted(() => {
  getGuideDetail()
  getComments()
})
</script>

<style lang="scss" scoped>
// 添加 text-overflow mixin
@mixin text-overflow($lines) {
  display: -webkit-box;
  -webkit-box-orient: vertical;
  -webkit-line-clamp: $lines;
  overflow: hidden;
  text-overflow: ellipsis;
}

.guide-detail {
  min-height: 100vh;
  background: #fff;
  position: relative;

  .back-btn {
    position: fixed;
    top: 20px;
    left: 20px;
    z-index: 100;
    width: 40px;
    height: 40px;
    border-radius: 50%;
    background: rgba(0, 0, 0, 0.6);
    color: #fff;
    display: flex;
    align-items: center;
    justify-content: center;
    cursor: pointer;
    transition: all 0.3s;
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.2);

    &:hover {
      background: rgba(0, 0, 0, 0.8);
      transform: scale(1.05);
    }
  }

  .cover-section {
    position: relative;
    height: 400px;
    
    .cover-image {
      width: 100%;
      height: 100%;
      object-fit: cover;
    }
    
    .cover-info {
      position: absolute;
      bottom: 0;
      left: 0;
      right: 0;
      padding: 40px 30px 30px;
      background: linear-gradient(transparent, rgba(0, 0, 0, 0.8));
      color: #fff;
      z-index: 2;
      
      h1 {
        margin: 0 0 15px;
        font-size: 32px;
        text-shadow: 0 2px 4px rgba(0, 0, 0, 0.3);
      }
      
      .meta-info {
        display: flex;
        gap: 20px;
        font-size: 14px;
        
        .el-icon {
          margin-right: 4px;
        }
        
        .category {
          background: rgba(255, 255, 255, 0.2);
          padding: 4px 12px;
          border-radius: 20px;
          backdrop-filter: blur(4px);
        }
      }
    }
  }

  .main-content {
    padding: 30px;
    position: relative;
    z-index: 3;
    background: #fff;
    border-radius: 20px 20px 0 0;
    margin-top: -20px;
    box-shadow: 0 -10px 20px rgba(0, 0, 0, 0.05);
    
    .content-wrapper {
      max-width: 800px;
      margin: 0 auto;
      
      .author-info {
        display: flex;
        align-items: center;
        gap: 15px;
        margin-bottom: 30px;
        padding: 20px;
        background: #f8f9fa;
        border-radius: 12px;
        box-shadow: 0 2px 12px rgba(0, 0, 0, 0.03);
        
        .author-meta {
          .name {
            font-size: 16px;
            font-weight: 500;
            margin-bottom: 4px;
          }
          
          .bio {
            font-size: 14px;
            color: #666;
          }
        }
      }
      
      .guide-content {
        margin-bottom: 30px;
        line-height: 1.8;
        color: #333;
        
        :deep(img) {
          max-width: 100%;
          border-radius: 8px;
          margin: 15px 0;
          box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
        }
        
        :deep(h1, h2, h3, h4, h5, h6) {
          margin: 25px 0 15px;
          color: #222;
        }
        
        :deep(p) {
          margin: 15px 0;
          font-size: 16px;
        }
        
        :deep(a) {
          color: var(--el-color-primary);
          text-decoration: none;
          
          &:hover {
            text-decoration: underline;
          }
        }
        
        :deep(blockquote) {
          border-left: 4px solid #ddd;
          padding: 10px 15px;
          color: #666;
          background: #f9f9f9;
          margin: 20px 0;
        }
      }
      
      .related-spot {
        margin-bottom: 30px;
        
        h3 {
          margin: 0 0 15px;
          font-size: 20px;
          position: relative;
          padding-left: 12px;
          
          &::before {
            content: '';
            position: absolute;
            left: 0;
            top: 4px;
            height: 16px;
            width: 4px;
            background: var(--el-color-primary);
            border-radius: 2px;
          }
        }
        
        .spot-card {
          display: flex;
          gap: 15px;
          padding: 15px;
          background: #f8f9fa;
          border-radius: 12px;
          cursor: pointer;
          transition: all 0.3s;
          box-shadow: 0 2px 12px rgba(0, 0, 0, 0.03);
          
          &:hover {
            background: #f0f0f0;
            transform: translateY(-2px);
            box-shadow: 0 4px 15px rgba(0, 0, 0, 0.08);
          }
          
          .spot-image {
            width: 120px;
            height: 80px;
            border-radius: 8px;
            object-fit: cover;
          }
          
          .spot-info {
            flex: 1;
            
            .name {
              font-size: 16px;
              font-weight: 500;
              margin-bottom: 8px;
              color: #333;
            }
            
            .desc {
              font-size: 14px;
              color: #666;
              @include text-overflow(2);
              line-height: 1.5;
            }
          }
        }
      }
      
      .action-bar {
        display: flex;
        justify-content: center;
        gap: 20px;
        margin: 40px 0;
        
        .el-button {
          min-width: 120px;
          border-radius: 24px;
          padding: 10px 20px;
          transition: all 0.3s;
          
          &:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
          }
          
          .el-icon {
            margin-right: 6px;
          }
        }
      }
      
      .comment-section {
        background: #f8f9fa;
        padding: 25px;
        border-radius: 12px;
        margin-bottom: 40px;
        
        h3 {
          margin: 0 0 20px;
          font-size: 20px;
          position: relative;
          padding-left: 12px;
          
          &::before {
            content: '';
            position: absolute;
            left: 0;
            top: 4px;
            height: 16px;
            width: 4px;
            background: var(--el-color-primary);
            border-radius: 2px;
          }
        }
        
        .comment-input {
          margin-bottom: 30px;
          background: #fff;
          padding: 15px;
          border-radius: 8px;
          box-shadow: 0 2px 8px rgba(0, 0, 0, 0.03);
          
          .el-button {
            margin-top: 10px;
            float: right;
            border-radius: 20px;
          }
        }
        
        .comment-list {
          .comment-item {
            display: flex;
            gap: 15px;
            margin-bottom: 20px;
            background: #fff;
            padding: 15px;
            border-radius: 8px;
            box-shadow: 0 2px 8px rgba(0, 0, 0, 0.03);
            
            .comment-content {
              flex: 1;
              
              .comment-header {
                margin-bottom: 8px;
                
                .username {
                  font-weight: 500;
                  margin-right: 10px;
                  color: #333;
                }
                
                .time {
                  font-size: 12px;
                  color: #999;
                }
              }
              
              .comment-text {
                font-size: 14px;
                color: #333;
                line-height: 1.6;
              }
            }
          }
        }
        
        .load-more {
          display: flex;
          align-items: center;
          justify-content: center;
          gap: 8px;
          padding: 12px;
          color: #666;
          cursor: pointer;
          background: #fff;
          border-radius: 8px;
          margin-top: 15px;
          transition: all 0.3s;
          
          &:hover {
            color: var(--el-color-primary);
            background: #f0f0f0;
          }
        }
      }
    }
  }
}

// 响应式调整
@media (max-width: 768px) {
  .guide-detail {
    .cover-section {
      height: 300px;
      
      .cover-info h1 {
        font-size: 24px;
      }
    }
    
    .main-content {
      padding: 20px 15px;
    }
  }
}
</style> 
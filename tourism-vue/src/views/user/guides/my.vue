<template>
  <div class="my-guides">
    <div class="header">
      <h2>我的攻略</h2>
      <el-button type="primary" @click="showPublishDialog">
        <el-icon><Plus /></el-icon>
        发布攻略
      </el-button>
    </div>

    <div class="guides-list" v-loading="loading">
      <el-row :gutter="20">
        <el-col :span="8" v-for="guide in guides" :key="guide.id">
          <el-card class="guide-card">
            <div class="cover">
              <el-image :src="getMediaUrl(guide.coverUrl)" fit="cover" />
              <div class="category">{{ getCategoryText(guide.category) }}</div>
            </div>
            
            <div class="content">
              <h3 class="title" @click="goToDetail(guide.id)">{{ guide.title }}</h3>
              
              <div class="stats">
                <span>
                  <el-icon><View /></el-icon>
                  {{ guide.views }}
                </span>
                <span>
                  <el-icon><Star /></el-icon>
                  {{ guide.likeCount }}
                </span>
                <span>
                  <el-icon><ChatDotRound /></el-icon>
                  {{ guide.commentCount }}
                </span>
              </div>
              
              <div class="actions">
                <el-button-group>
                  <el-button @click="handleEdit(guide)">
                    <el-icon><Edit /></el-icon>
                    编辑
                  </el-button>
                  <el-button type="danger" @click="handleDelete(guide)">
                    <el-icon><Delete /></el-icon>
                    删除
                  </el-button>
                </el-button-group>
              </div>
            </div>
          </el-card>
        </el-col>
      </el-row>
      
      <!-- 加载更多 -->
      <div v-if="hasMore" class="load-more">
        <el-button type="primary" text @click="loadMore">
          加载更多 <el-icon class="el-icon--right"><ArrowDown /></el-icon>
        </el-button>
      </div>
    </div>

    <!-- 发布/编辑对话框 -->
    <el-dialog
      v-model="guideDialog.visible"
      :title="guideDialog.type === 'create' ? '发布攻略' : '编辑攻略'"
      width="60%"
    >
      <el-form :model="guideDialog.form" label-width="80px">
        <el-form-item label="标题">
          <el-input v-model="guideDialog.form.title" placeholder="请输入标题" />
        </el-form-item>
        
        <el-form-item label="分类">
          <el-select v-model="guideDialog.form.category" placeholder="请选择分类">
            <el-option label="景点玩法" value="spot" />
            <el-option label="美食推荐" value="food" />
            <el-option label="住宿建议" value="hotel" />
            <el-option label="交通指南" value="traffic" />
          </el-select>
        </el-form-item>
        
        <el-form-item label="封面图">
          <el-upload
            class="avatar-uploader"
            :action="`${baseURL}/api/file/upload`"
            :headers="uploadHeaders"
            :show-file-list="false"
            :before-upload="beforeCoverUpload"
            :on-success="handleCoverSuccess"
          >
            <img v-if="guideDialog.form.coverUrl" :src="getMediaUrl(guideDialog.form.coverUrl)" class="avatar" />
            <el-icon v-else class="avatar-uploader-icon"><Plus /></el-icon>
          </el-upload>
        </el-form-item>
        
        <el-form-item label="内容">
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
        <el-button type="primary" @click="handleSubmitGuide">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import request from '@/utils/request'

const router = useRouter()
const loading = ref(false)
const guides = ref([])
const page = ref(1)
const pageSize = ref(12)
const hasMore = ref(true)
const baseURL = 'http://localhost:8080'

// 获取个人攻略列表
const getMyGuides = async (isLoadMore = false) => {
  try {
    loading.value = true
    const { data: res } = await request.get('/api/guide/my', {
      params: {
        page: page.value,
        pageSize: pageSize.value
      }
    })
    
    if (res.code === 200) {
      if (isLoadMore) {
        guides.value.push(...res.data.records)
      } else {
        guides.value = res.data.records
      }
      hasMore.value = res.data.hasMore
    }
  } catch (error) {
    console.error('获取攻略列表失败:', error)
    ElMessage.error('获取攻略列表失败')
  } finally {
    loading.value = false
  }
}

// 加载更多
const loadMore = () => {
  if (loading.value || !hasMore.value) return
  page.value++
  getMyGuides(true)
}

// ... 其他方法保持不变 ...

onMounted(() => {
  getMyGuides()
})
</script>

<style lang="scss" scoped>
.my-guides {
  padding: 20px;
  
  .header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 20px;
    
    h2 {
      margin: 0;
    }
  }
  
  .guide-card {
    margin-bottom: 20px;
    
    .cover {
      position: relative;
      height: 200px;
      
      .el-image {
        width: 100%;
        height: 100%;
      }
      
      .category {
        position: absolute;
        top: 10px;
        left: 10px;
        padding: 4px 8px;
        background: rgba(0,0,0,0.6);
        color: #fff;
        border-radius: 4px;
      }
    }
    
    .content {
      padding: 15px;
      
      .title {
        margin: 0 0 15px;
        font-size: 16px;
        cursor: pointer;
        
        &:hover {
          color: var(--el-color-primary);
        }
      }
      
      .stats {
        display: flex;
        gap: 15px;
        margin-bottom: 15px;
        color: #666;
        
        span {
          display: flex;
          align-items: center;
          gap: 4px;
        }
      }
    }
  }
}

// ... 其他样式保持不变 ...
</style> 
<template>
  <div class="guides-container">
    <!-- 搜索栏 -->
    <div class="search-bar">
      <el-form :inline="true" :model="searchForm">
        <el-form-item>
          <el-input
            v-model="searchForm.keyword"
            placeholder="标题/内容"
            clearable
            @keyup.enter="handleSearch"
          />
        </el-form-item>
        <el-form-item>
          <el-select v-model="searchForm.category" placeholder="攻略分类" clearable>
            <el-option
              v-for="item in categories"
              :key="item.value"
              :label="item.label"
              :value="item.value"
            />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-select v-model="searchForm.status" placeholder="状态" clearable>
            <el-option label="待审核" value="0" />
            <el-option label="已发布" value="1" />
            <el-option label="已拒绝" value="2" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="handleSearch">搜索</el-button>
          <el-button @click="resetSearch">重置</el-button>
          <el-button type="success" @click="handleAdd">新增攻略</el-button>
        </el-form-item>
      </el-form>
    </div>

    <!-- 攻略列表 -->
    <el-table
      v-loading="loading"
      :data="guideList"
      style="width: 100%"
    >
      <el-table-column prop="title" label="标题" min-width="200" show-overflow-tooltip />
      
      <el-table-column prop="category" label="分类" width="100">
        <template #default="{ row }">
          <el-tag>{{ getCategoryLabel(row.category) }}</el-tag>
        </template>
      </el-table-column>
      
      <el-table-column prop="views" label="浏览量" width="100" align="center" />
      
      <el-table-column prop="likeCount" label="点赞数" width="100" align="center" />
      
      <el-table-column prop="commentCount" label="评论数" width="100" align="center" />
      
      <el-table-column prop="status" label="状态" width="100" align="center">
        <template #default="{ row }">
          <el-tag :type="getStatusType(row.status)">
            {{ getStatusLabel(row.status) }}
          </el-tag>
        </template>
      </el-table-column>
      
      <el-table-column prop="createdTime" label="创建时间" width="180">
        <template #default="{ row }">
          {{ formatTime(row.createdTime) }}
        </template>
      </el-table-column>
      
      <el-table-column label="封面图" width="120">
        <template #default="{ row }">
          <el-image 
            v-if="row.coverUrl"
            :src="getMediaUrl(row.coverUrl)"
            style="width: 100px; height: 60px; object-fit: cover"
            :preview-src-list="[getMediaUrl(row.coverUrl)]"
          />
          <span v-else>无</span>
        </template>
      </el-table-column>
      
      <el-table-column label="操作" width="250" fixed="right">
        <template #default="{ row }">
          <el-button-group>
            <el-button
              type="primary"
              size="small"
              @click="handleEdit(row)"
            >
              编辑
            </el-button>
            <el-button
              type="success"
              size="small"
              v-if="row.status === 0"
              @click="handleAudit(row, 1)"
            >
              通过
            </el-button>
            <el-button
              type="danger"
              size="small"
              v-if="row.status === 0"
              @click="handleAudit(row, 2)"
            >
              拒绝
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
        v-model:current-page="page"
        v-model:page-size="size"
        :page-sizes="[5,10, 20, 50, 100]"
        :total="total"
        layout="total, sizes, prev, pager, next, jumper"
        @size-change="handleSizeChange"
        @current-change="handleCurrentChange"
      />
    </div>

    <!-- 编辑对话框 -->
    <el-dialog
      :title="dialogTitle"
      v-model="dialogVisible"
      width="800px"
    >
      <el-form
        ref="formRef"
        :model="form"
        :rules="rules"
        label-width="100px"
      >
        <el-form-item label="标题" prop="title">
          <el-input v-model="form.title" />
        </el-form-item>
        
        <el-form-item label="分类" prop="category">
          <el-select v-model="form.category" placeholder="请选择分类">
            <el-option
              v-for="item in categories"
              :key="item.value"
              :label="item.label"
              :value="item.value"
            />
          </el-select>
        </el-form-item>
        
        <el-form-item label="关联景点" prop="spotId">
          <el-select
            v-model="form.spotId"
            placeholder="请选择景点"
            filterable
            clearable
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
            :action="uploadAction"
            :headers="uploadHeaders"
            :show-file-list="false"
            :before-upload="beforeUpload"
            :on-success="handleUploadSuccess"
            :on-remove="handleRemove"
            :data="{ type: 'image' }"
          >
            <img v-if="form.coverUrl" :src="getMediaUrl(form.coverUrl)" class="avatar">
            <el-icon v-else class="avatar-uploader-icon"><Plus /></el-icon>
          </el-upload>
          <div v-if="form.coverUrl" class="image-actions">
            <el-button type="danger" size="small" @click="handleRemove">删除图片</el-button>
          </div>
        </el-form-item>
        
        <el-form-item label="内容" prop="content">
          <el-input
            v-model="form.content"
            type="textarea"
            :rows="10"
            placeholder="支持Markdown格式"
          />
        </el-form-item>
      </el-form>
      
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleSubmit">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus } from '@element-plus/icons-vue'
import request from '@/utils/request'
import { formatTime, getMediaUrl, categories as categoryOptions } from '@/utils'

// 响应式状态
const loading = ref(false)
const dialogVisible = ref(false)
const dialogTitle = ref('')
const formRef = ref(null)
const page = ref(1)
const size = ref(5)
const total = ref(0)
const guideList = ref([])
const spotList = ref([])

// 搜索表单
const searchForm = ref({
  keyword: '',
  category: '',
  status: ''
})

// 编辑表单
const form = ref({
  id: null,
  title: '',
  category: '',
  spotId: null,
  coverUrl: '',
  content: '',
  status: 1
})

// 表单验证规则
const rules = {
  title: [
    { required: true, message: '请输入标题', trigger: 'blur' },
    { min: 2, max: 50, message: '长度在 2 到 50 个字符', trigger: 'blur' }
  ],
  category: [
    { required: true, message: '请选择分类', trigger: 'change' }
  ],
  content: [
    { required: true, message: '请输入内容', trigger: 'blur' }
  ]
}

// 分类选项
const categories = [
  { value: 'travel', label: '游记攻略' },
  { value: 'food', label: '美食推荐' },
  { value: 'hotel', label: '住宿推荐' },
  { value: 'shopping', label: '购物指南' },
  { value: 'traffic', label: '交通指南' }
]

// 上传相关配置
const uploadHeaders = computed(() => ({
  Authorization: localStorage.getItem('token')
}))

const uploadAction = computed(() => {
  return `${import.meta.env.VITE_API_URL}/api/file/guide/upload`
})

// 获取攻略列表
const getGuideList = async () => {
  try {
    loading.value = true
    const { data: res } = await request.get('/api/guide', {
      params: {
        page: page.value,
        pageSize: size.value,
        ...searchForm.value
      }
    })
    if (res.code === 200) {
      guideList.value = res.data.records
      total.value = res.data.total
    }
  } catch (error) {
    console.error('获取攻略列表失败:', error)
    ElMessage.error('获取攻略列表失败')
  } finally {
    loading.value = false
  }
}

// 获取景点列表
const getSpotList = async () => {
  try {
    const { data: res } = await request.get('/api/spots/list')
    if (res.code === 200) {
      spotList.value = res.data.records
    }
  } catch (error) {
    console.error('获取景点列表失败:', error)
  }
}

// 处理搜索
const handleSearch = () => {
  page.value = 1
  getGuideList()
}

// 重置搜索
const resetSearch = () => {
  searchForm.value = {
    keyword: '',
    category: '',
    status: ''
  }
  handleSearch()
}

// 处理分页大小改变
const handleSizeChange = (val) => {
  size.value = val
  getGuideList()
}

// 处理页码改变
const handleCurrentChange = (val) => {
  page.value = val
  getGuideList()
}

// 处理新增
const handleAdd = () => {
  dialogTitle.value = '新增攻略'
  form.value = {
    id: null,
    title: '',
    category: '',
    spotId: null,
    coverUrl: '',
    content: '',
    status: 1
  }
  dialogVisible.value = true
}

// 处理编辑
const handleEdit = (row) => {
  dialogTitle.value = '编辑攻略'
  form.value = { ...row }
  dialogVisible.value = true
}

// 处理删除
const handleDelete = async (row) => {
  try {
    await ElMessageBox.confirm('确定要删除该攻略吗？', '提示', {
      type: 'warning'
    })
    
    const res = await request.delete(`/api/guide/${row.id}`)
    if (res.data.code === 200) {
      ElMessage.success('删除成功')
      getGuideList()
    } else {
      ElMessage.error(res.data.msg || '删除失败')
    }
  } catch (error) {
    if (error !== 'cancel') {
      console.error('删除失败:', error)
      ElMessage.error('删除失败')
    }
  }
}

// 处理审核
const handleAudit = async (row, status) => {
  try {
    const { data: res } = await request.put(`/api/guide/${row.id}/status`, {
      status
    })
    if (res.code === 200) {
      ElMessage.success('操作成功')
      getGuideList()
    }
  } catch (error) {
    console.error('操作失败:', error)
    ElMessage.error('操作失败')
  }
}

// 处理上传成功
const handleUploadSuccess = (res) => {
  if (res.code === 200) {
    form.value.coverUrl = res.data
    ElMessage.success('上传成功')
  } else {
    ElMessage.error(res.msg || '上传失败')
  }
}

// 处理移除图片
const handleRemove = () => {
  if (form.value.coverUrl) {
    // 如果是编辑状态，需要调用后端接口删除原图片
    if (form.value.id) {
      request.delete('/api/file/delete', {
        params: { filePath: form.value.coverUrl }
      }).then(() => {
        form.value.coverUrl = ''
      })
    } else {
      form.value.coverUrl = ''
    }
  }
}

// 上传前验证
const beforeUpload = (file) => {
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

// 处理表单提交
const handleSubmit = async () => {
  if (!formRef.value) return
  
  try {
    await formRef.value.validate()
    
    const data = {
      ...form.value,
      coverUrl: form.value.coverUrl
    }
    
    const url = form.value.id ? `/api/guide/${form.value.id}` : '/api/guide'
    const method = form.value.id ? 'put' : 'post'
    
    const res = await request({
      url,
      method,
      data
    })
    
    if (res.data.code === 200) {
      ElMessage.success(form.value.id ? '更新成功' : '添加成功')
      dialogVisible.value = false
      getGuideList()
    } else {
      ElMessage.error(res.data.msg || '操作失败')
    }
  } catch (error) {
    console.error('提交失败:', error)
    ElMessage.error('提交失败')
  }
}

// 获取分类标签
const getCategoryLabel = (value) => {
  const category = categories.find(item => item.value === value)
  return category ? category.label : value
}

// 获取状态标签
const getStatusLabel = (status) => {
  switch (status) {
    case 0: return '待审核'
    case 1: return '已发布'
    case 2: return '已拒绝'
    default: return '未知'
  }
}

// 获取状态类型
const getStatusType = (status) => {
  switch (status) {
    case 0: return 'warning'
    case 1: return 'success'
    case 2: return 'danger'
    default: return 'info'
  }
}

// 处理状态更新
const handleStatusChange = async (row) => {
  try {
    const res = await request.put(`/api/guide/${row.id}/status`, {
      status: row.status
    })
    
    if (res.data.code === 200) {
      ElMessage.success('状态更新成功')
      getGuideList()
    } else {
      ElMessage.error(res.data.msg || '状态更新失败')
    }
  } catch (error) {
    console.error('状态更新失败:', error)
    ElMessage.error('状态更新失败')
  }
}

// 初始化
onMounted(() => {
  getGuideList()
  getSpotList()
})
</script>

<style lang="scss" scoped>
.guides-container {
  padding: 20px;

  .search-bar {
    margin-bottom: 20px;
  }

  .pagination {
    margin-top: 20px;
    display: flex;
    justify-content: flex-end;
  }

  .avatar-uploader {
    :deep(.el-upload) {
      border: 1px dashed #d9d9d9;
      border-radius: 6px;
      cursor: pointer;
      position: relative;
      overflow: hidden;
      transition: var(--el-transition-duration-fast);

      &:hover {
        border-color: var(--el-color-primary);
      }
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

  .image-actions {
    margin-top: 8px;
    display: flex;
    gap: 8px;
  }
}
</style>
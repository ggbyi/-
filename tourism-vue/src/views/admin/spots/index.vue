<template>
  <div class="spots-container">
    <!-- 搜索栏 -->
    <div class="search-bar">
      <el-form :inline="true" :model="searchForm">
        <el-form-item>
          <el-input
            v-model="searchForm.keyword"
            placeholder="景点名称/描述"
            clearable
            @keyup.enter="handleSearch"
          />
        </el-form-item>
        <el-form-item>
          <el-popover
            placement="bottom"
            :width="400"
            trigger="click"
          >
            <template #reference>
              <el-select v-model="searchForm.categoryId" placeholder="景点分类" clearable>
                <el-option
                  v-for="item in categories"
                  :key="item.id"
                  :label="item.name"
                  :value="item.id"
                />
                <template #prefix>
                  <el-icon><Management /></el-icon>
                </template>
              </el-select>
            </template>

            <!-- 分类管理弹出框 -->
            <div class="category-manager">
              <div class="header">
                <h3>分类管理</h3>
                <el-button type="primary" size="small" @click="handleAddCategory">
                  添加分类
                </el-button>
              </div>

              <el-table :data="categories" size="small" style="width: 100%">
                <el-table-column prop="name" label="分类名称" />
                <el-table-column label="创建时间" width="180">
                  <template #default="{ row }">
                    {{ formatTime(row.createTime) }}
                  </template>
                </el-table-column>
                <el-table-column label="操作" width="150" align="right">
                  <template #default="{ row }">
                    <el-button-group>
                      <el-button
                        type="primary"
                        size="small"
                        @click="handleEditCategory(row)"
                      >
                        编辑
                      </el-button>
                      <el-button
                        type="danger"
                        size="small"
                        @click="handleDeleteCategory(row)"
                      >
                        删除
                      </el-button>
                    </el-button-group>
                  </template>
                </el-table-column>
              </el-table>
            </div>
          </el-popover>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="handleSearch">搜索</el-button>
          <el-button @click="resetSearch">重置</el-button>
          <el-button type="success" @click="handleAdd">添加景点</el-button>
        </el-form-item>
      </el-form>
    </div>

    <!-- 景点列表 -->
    <el-table
      v-loading="loading"
      :data="spotList"
      style="width: 100%"
    >
      <el-table-column label="景点信息" min-width="300">
        <template #default="{ row }">
          <div class="spot-info">
            <div class="image-wrapper">
              <el-image
                :src="getMediaUrl(row.coverUrl)"
                fit="cover"
                :preview-src-list="row.images ? row.images.split(',').map(getMediaUrl) : []"
                :initial-index="0"
                preview-teleported
                class="spot-image"
              />
            </div>
            <div class="info">
              <h3>{{ row.name }}</h3>
              <p>{{ row.description }}</p>
            </div>
          </div>
        </template>
      </el-table-column>

      <el-table-column prop="categoryName" label="分类" width="120" />
      <el-table-column prop="price" label="门票价格" width="100" />
      <el-table-column label="营业时间" width="200">
        <template #default="{ row }">
          {{ row.openTime }} - {{ row.closeTime }}
        </template>
      </el-table-column>

      <el-table-column label="状态" width="100">
        <template #default="{ row }">
          <el-switch
            v-model="row.status"
            :active-value="1"
            :inactive-value="0"
            @change="handleStatusChange(row)"
          />
        </template>
      </el-table-column>

      <el-table-column label="操作" width="200" fixed="right">
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
        background
        v-model:current-page="page"
        v-model:page-size="size"
        :total="total"
        :page-sizes="[5, 10, 20, 50, 100]"
        layout="total, sizes, prev, pager, next"
        @size-change="handleSizeChange"
        @current-change="handleCurrentChange"
      />
    </div>

    <!-- 添加/编辑对话框 -->
    <el-dialog
      :title="dialogTitle"
      v-model="dialogVisible"
      width="700px"
    >
      <el-form
        ref="formRef"
        :model="form"
        :rules="rules"
        label-width="100px"
      >
        <el-form-item label="景点名称" prop="name">
          <el-input v-model="form.name" />
        </el-form-item>

        <el-form-item label="所属分类" prop="categoryId">
          <el-select v-model="form.categoryId" placeholder="请选择分类">
            <el-option
              v-for="item in categories"
              :key="item.id"
              :label="item.name"
              :value="item.id"
            />
          </el-select>
        </el-form-item>

        <el-form-item label="门票价格" prop="price">
          <el-input-number v-model="form.price" :min="0" :precision="2" />
        </el-form-item>

        <el-form-item label="营业时间">
          <el-time-picker
            v-model="form.openTime"
            format="HH:mm"
            value-format="HH:mm"
            placeholder="开始时间"
            :disabled-hours="disabledHours"
            :disabled-minutes="disabledMinutes"
          />
          <span class="mx-2">-</span>
          <el-time-picker
            v-model="form.closeTime"
            format="HH:mm"
            value-format="HH:mm"
            placeholder="结束时间"
            :disabled-hours="disabledHours"
            :disabled-minutes="disabledMinutes"
            :min-time="form.openTime"
          />
        </el-form-item>

        <el-form-item label="景点图片">
          <el-upload
            class="upload-list"
            :action="`${apiUrl}/api/file/upload`"
            :headers="getHeaders()"
            :data="{ type: 'image' }"
            list-type="picture-card"
            :file-list="imageList"
            :on-success="handleUploadSuccess"
            :on-error="handleUploadError"
            :on-remove="handleRemove"
            :before-upload="beforeImageUpload"
            multiple
            accept="image/*"
          >
            <el-icon><Plus /></el-icon>
          </el-upload>

          <!-- 使用独立的预览对话框 -->
          <el-dialog
            v-model="previewVisible"
            append-to-body
            :modal-append-to-body="false"
            width="800px"
            class="preview-dialog"
          >
            <img :src="previewUrl" alt="Preview" class="preview-image">
          </el-dialog>
        </el-form-item>

        <el-form-item label="景点视频">
          <el-upload
            class="upload-video"
            :action="`${apiUrl}/api/file/upload`"
            :headers="getHeaders()"
            :data="{ type: 'video' }"
            :file-list="videoList"
            :on-success="handleVideoUploadSuccess"
            :on-error="handleUploadError"
            :before-upload="beforeVideoUpload"
            :limit="1"
            accept="video/mp4,video/webm"
          >
            <el-button type="primary">
              {{ form.videoUrl ? '重新上传' : '上传视频' }}
            </el-button>
          </el-upload>

          <!-- 视频预览 -->
          <div v-if="form.videoUrl" class="video-preview">
            <video
              :src="getMediaUrl(form.videoUrl)"
              class="preview-video"
              controls
              preload="metadata"
            >
              您的浏览器不支持视频播放
            </video>
          </div>

          <!-- 视频预览对话框 -->
          <el-dialog
            v-model="videoPreviewVisible"
            append-to-body
            :modal-append-to-body="false"
            width="800px"
            class="video-preview-dialog"
            destroy-on-close
          >
            <video
              :src="videoPreviewUrl"
              class="preview-video-full"
              controls
              autoplay
            >
              您的浏览器不支持视频播放
            </video>
          </el-dialog>
        </el-form-item>

        <el-form-item label="景点位置" prop="location">
          <el-input v-model="form.location" placeholder="请输入景点位置" />
        </el-form-item>

        <el-form-item label="详细地址">
          <el-input v-model="form.address" placeholder="请输入详细地址（选填）" />
        </el-form-item>

        <el-form-item label="景点描述" prop="description">
          <el-input
            v-model="form.description"
            type="textarea"
            :rows="4"
          />
        </el-form-item>
      </el-form>

      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleSubmit">确定</el-button>
      </template>
    </el-dialog>

    <!-- 分类编辑对话框 -->
    <el-dialog
      :title="categoryDialogTitle"
      v-model="categoryDialogVisible"
      width="400px"
    >
      <el-form
        ref="categoryFormRef"
        :model="categoryForm"
        :rules="categoryRules"
        label-width="80px"
      >
        <el-form-item label="分类名称" prop="name">
          <el-input v-model="categoryForm.name" />
        </el-form-item>
      </el-form>
      <template #footer>
        <span class="dialog-footer">
          <el-button @click="categoryDialogVisible = false">取消</el-button>
          <el-button type="primary" @click="handleCategorySubmit">确定</el-button>
        </span>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted, onUnmounted, computed } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import {
  Plus,
  Picture,
  Location,
  View,
  Star,
  Ticket,
  Management
} from '@element-plus/icons-vue'
import * as echarts from 'echarts'
import request from '@/utils/request'
import { formatTime } from '@/utils/format'

// 获取环境变量和 token
const apiUrl = import.meta.env.VITE_API_URL
const getHeaders = () => {
  const token = localStorage.getItem('token')
  return token ? { Authorization: token } : {}
}

// 分页参数
const page = ref(1)
const size = ref(5)
const total = ref(0)

// 搜索表单
const searchForm = ref({
  keyword: '',
  categoryId: null
})

// 重置搜索
const resetSearch = () => {
  searchForm.value = {
    keyword: '',
    categoryId: null
  }
  handleSearch()
}

// 景点列表
const loading = ref(false)
const spotList = ref([])

// 获取景点列表
const getSpotList = async () => {
  loading.value = true
  try {
    const res = await request.get('/api/spots/list', {
      params: {
        page: page.value,
        size: size.value,
        keyword: searchForm.value.keyword,
        categoryId: searchForm.value.categoryId
      }
    })
    if (res.data.code === 200) {
      spotList.value = res.data.data.records
      total.value = res.data.data.total
    } else {
      ElMessage.error(res.data.msg || '获取景点列表失败')
    }
  } catch (error) {
    console.error('获取景点列表失败:', error)
    ElMessage.error('获取景点列表失败')
  } finally {
    loading.value = false
  }
}

// 处理分页大小改变
const handleSizeChange = (val) => {
  size.value = val
  page.value = 1
  getSpotList()
}

// 处理页码改变
const handleCurrentChange = (val) => {
  page.value = val
  getSpotList()
}

// 处理搜索
const handleSearch = () => {
  page.value = 1
  getSpotList()
}

// 表单对话框
const dialogVisible = ref(false)
const dialogTitle = ref('')
const formRef = ref(null)
const form = ref({
  id: null,
  name: '',
  categoryId: '',
  location: '',
  address: '',
  price: 0,
  openTime: '',
  closeTime: '',
  description: '',
  images: '',
  videoUrl: '',
  coverUrl: '',
  status: 1
})

// 表单验证规则
const rules = {
  name: [
    { required: true, message: '请输入景点名称', trigger: 'blur' },
    { min: 2, max: 50, message: '长度在 2 到 50 个字符', trigger: 'blur' }
  ],
  categoryId: [
    { required: true, message: '请选择所属分类', trigger: 'change' }
  ],
  price: [
    { required: true, message: '请输入门票价格', trigger: 'blur' }
  ],
  openTime: [
    { required: true, message: '请选择开放时间', trigger: 'change' }
  ],
  closeTime: [
    { required: true, message: '请选择关闭时间', trigger: 'change' }
  ],
  description: [
    { required: true, message: '请输入景点介绍', trigger: 'blur' }
  ],
  location: [
    { required: true, message: '请输入景点位置', trigger: 'blur' }
  ]
}

// 标签选项
const tagOptions = [
  '亲子游',
  '情侣游',
  '户外探险',
  '摄影',
  '美食',
  '历史',
  '文化',
  '自然',
  '购物',
  '度假'
]

// 记录要上传的文件
const newImages = ref([])
const newVideo = ref(null)

// 处理图片选择改变
const handleImageChange = (uploadFile) => {
  if (uploadFile.status === 'ready') {
    const file = uploadFile.raw
    // 检查是否已经存在相同的文件
    const exists = newImages.value.some(img => img.raw.name === file.name)
    if (exists) {
      return
    }

    // 创建本地预览URL
    const url = URL.createObjectURL(file)

    // 保存文件和预览URL到临时列表
    newImages.value.push({
      raw: file,
      url: url
    })

    // 更新上传列表显示
    uploadFile.url = url

    // 更新表单显示
    const imageUrls = form.value.images ? form.value.images.split(',') : []
    if (!imageUrls.includes(url)) {
      imageUrls.push(url)
      form.value.images = imageUrls.join(',')

      // 如果没有封面图，设置第一张图片为封面图
      if (!form.value.coverUrl) {
        form.value.coverUrl = url
      }
    }
  }
}

// 处理视频选择改变
const handleVideoChange = (uploadFile) => {
  if (uploadFile.status === 'ready') {
    const file = uploadFile.raw
    // 创建本地预览URL
    const url = URL.createObjectURL(file)

    // 保存文件和预览URL
    newVideo.value = {
      raw: file,
      url: url
    }

    // 更新上传列表显示
    uploadFile.url = url

    // 更新表单显示
    form.value.videoUrl = url
  }
}

// 提交表单
const handleSubmit = async () => {
  if (!formRef.value) return

  try {
    await formRef.value.validate()
    
    // 创建 FormData 对象
    const formData = new FormData()
    
    // 将表单数据转换为 JSON 字符串并添加到 FormData
    formData.append('spot', new Blob([JSON.stringify(form.value)], {
      type: 'application/json'
    }))

    const url = form.value.id ? `/api/spots/${form.value.id}` : '/api/spots'
    const method = form.value.id ? 'put' : 'post'

    const res = await request({
      url,
      method,
      data: formData,
      headers: {
        'Content-Type': 'multipart/form-data'
      }
    })

    if (res.data.code === 200) {
      ElMessage.success(form.value.id ? '更新成功' : '添加成功')
      dialogVisible.value = false
      getSpotList()
    } else {
      ElMessage.error(res.data.msg || (form.value.id ? '更新失败' : '添加失败'))
    }
  } catch (error) {
    console.error('提交失败:', error)
    ElMessage.error(form.value.id ? '更新失败' : '添加失败')
  }
}

// 打开添加对话框
const handleAdd = () => {
  cleanupFiles()
  form.value = {
    name: '',
    categoryId: '',
    location: '',
    address: '',
    price: 0,
    openTime: '',
    closeTime: '',
    description: '',
    images: '',
    videoUrl: '',
    coverUrl: '',
    status: 1
  }
  dialogVisible.value = true
}

// 打开编辑对话框
const handleEdit = (row) => {
  cleanupFiles()
  form.value = { ...row }
  dialogVisible.value = true
}

// 记录要删除的图片
const deletedImages = ref([])
const deletedVideo = ref(false)

// 处理图片移除
const handleRemove = (file) => {
  // 从数据库路径中找到对应的图片URL
  const imageUrls = form.value.images ? form.value.images.split(',') : []
  const index = imageUrls.findIndex(url => getMediaUrl(url) === file.url)

  if (index !== -1) {
    const imageUrl = imageUrls[index]
    // 添加到待删除列表
    deletedImages.value.push(imageUrl)
    // 从数组中移除该图片URL
    imageUrls.splice(index, 1)
    form.value.images = imageUrls.join(',')

    // 如果删除的是封面图，更新封面图
    if (getMediaUrl(form.value.coverUrl) === file.url) {
      form.value.coverUrl = imageUrls[0] || ''
    }
  }
}

// 处理视频移除
const handleVideoRemove = () => {
  if (form.value.videoUrl) {
    deletedVideo.value = true
    form.value.videoUrl = ''
  }
}

// 删除景点
const handleDelete = async (row) => {
  try {
    await ElMessageBox.confirm('确定要删除该景点吗？此操作不可恢复！', '警告', {
      type: 'warning'
    })
    const res = await request.delete(`/api/spots/${row.id}`)
    if (res.data.code === 200) {
      ElMessage.success('删除成功')
      getSpotList()
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

// 修改状态
const handleStatusChange = async (row) => {
  try {
    const formData = new FormData()
    formData.append('spot', new Blob([JSON.stringify({
      id: row.id,
      status: row.status
    })], {
      type: 'application/json'
    }))

    const res = await request({
      url: `/api/spots/${row.id}/status`,
      method: 'put',
      data: formData,
      headers: {
        'Content-Type': 'multipart/form-data'
      }
    })

    if (res.data.code === 200) {
      ElMessage.success('状态更新成功')
    } else {
      row.status = row.status === 1 ? 0 : 1 // 恢复状态
      ElMessage.error(res.data.msg || '状态更新失败')
    }
  } catch (error) {
    row.status = row.status === 1 ? 0 : 1 // 恢复状态
    console.error('状态更新失败:', error)
    ElMessage.error('状态更新失败')
  }
}

// 景点详情
const drawerVisible = ref(false)
const detail = ref({})
const ratingChartRef = ref(null)
const ratingChart = ref(null)

// 查看详情
const handleViewDetail = async (row) => {
  try {
    const res = await request.get(`/admin/spots/${row.id}/detail`)
    detail.value = res.data
    drawerVisible.value = true

    // 等待DOM更新后初始化图表
    setTimeout(() => {
      initRatingChart()
    }, 0)
  } catch (error) {
    console.error('获取景点详情失败:', error)
  }
}

// 初始化评分分布图表
const initRatingChart = () => {
  if (!ratingChartRef.value) return

  ratingChart.value = echarts.init(ratingChartRef.value)
  const option = {
    tooltip: {
      trigger: 'item'
    },
    legend: {
      orient: 'vertical',
      right: 10,
      top: 'center'
    },
    series: [
      {
        name: '评分分布',
        type: 'pie',
        radius: ['40%', '70%'],
        avoidLabelOverlap: false,
        itemStyle: {
          borderRadius: 10,
          borderColor: '#fff',
          borderWidth: 2
        },
        label: {
          show: false
        },
        emphasis: {
          label: {
            show: true,
            fontSize: '14',
            fontWeight: 'bold'
          }
        },
        labelLine: {
          show: false
        },
        data: [
          { value: detail.value.rating5Count || 0, name: '5星' },
          { value: detail.value.rating4Count || 0, name: '4星' },
          { value: detail.value.rating3Count || 0, name: '3星' },
          { value: detail.value.rating2Count || 0, name: '2星' },
          { value: detail.value.rating1Count || 0, name: '1星' }
        ]
      }
    ]
  }
  ratingChart.value.setOption(option)
}

// 图片预览相关
const previewVisible = ref(false)
const previewUrl = ref('')

// 处理图片预览
const handlePictureCardPreview = (file) => {
  previewUrl.value = file.url
  previewVisible.value = true
}

// 处理视频预览相关
const videoPreviewVisible = ref(false)
const videoPreviewUrl = ref('')

// 处理视频上传前的验证
const beforeVideoUpload = (file) => {


  const isValidFormat = ['video/mp4', 'video/webm'].includes(file.type)
  const isLt100M = file.size / 1024 / 1024 < 100

  if (!isValidFormat) {
    ElMessage.error('只能上传 MP4 或 WebM 格式的视频!')
    return false
  }
  if (!isLt100M) {
    ElMessage.error('视频大小不能超过 100MB!')
    return false
  }

  // 如果已经有视频，提示用户
  if (form.value.videoUrl) {
    return ElMessageBox.confirm('上传新视频将替换当前视频，是否继续？', '提示', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    })
  }

  return true
}

// 视频预览
const handleVideoPreview = (file) => {
  videoPreviewUrl.value = getMediaUrl(form.value.videoUrl)
  videoPreviewVisible.value = true
}

// 工具函数
const getCategoryText = (category) => {
  const map = {
    NATURAL: '自然风光',
    CULTURAL: '人文历史',
    LEISURE: '休闲娱乐'
  }
  return map[category] || category
}

// 监听窗口大小变化
const handleResize = () => {
  ratingChart.value?.resize()
}

// 生命周期钩子
onMounted(() => {
  getSpotList()
  window.addEventListener('resize', handleResize)
})

onUnmounted(() => {
  window.removeEventListener('resize', handleResize)
  ratingChart.value?.dispose()
  newImages.value.forEach(image => URL.revokeObjectURL(image.url))
  if (newVideo.value) {
    URL.revokeObjectURL(newVideo.value.url)
  }
})

// 分类相关
const categories = ref([])
const categoryDialogVisible = ref(false)
const categoryDialogTitle = ref('')
const categoryFormRef = ref()
const categoryForm = ref({
  id: null,
  name: ''
})

const categoryRules = {
  name: [
    { required: true, message: '请输入分类名称', trigger: 'blur' },
    { min: 2, max: 20, message: '长度在 2 到 20 个字符', trigger: 'blur' }
  ]
}

// 获取分类列表
const getCategories = async () => {
  try {
    const res = await request.get('/api/spot/category/list')
    console.log("111")
    if (res.data.code === 200) {
      console.log("111")
      categories.value = [
        { id: '', name: '全部' },
        ...res.data.data  // 直接使用 res.data，因为它已经是分类数组
      ]
    } else {
      ElMessage.error(res.data.msg || '获取分类列表失败')
    }
  } catch (error) {
    console.error('获取分类失败:', error)
    ElMessage.error('获取分类列表失败')
  }
}

// 添加分类
const handleAddCategory = () => {
  categoryDialogTitle.value = '添加分类'
  categoryForm.value = {
    id: null,
    name: ''
  }
  categoryDialogVisible.value = true
}

// 编辑分类
const handleEditCategory = (row) => {
  categoryDialogTitle.value = '编辑分类'
  categoryForm.value = { ...row }
  categoryDialogVisible.value = true
}

// 删除分类
const handleDeleteCategory = async (row) => {
  try {
    await ElMessageBox.confirm('确定要删除该分类吗？此操作不可恢复！', '警告', {
      type: 'warning'
    })
    const res = await request.delete(`/api/spot/category/${row.id}`)
    if (res.data.code === 200) {
      ElMessage.success('删除成功')
      getCategories()
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

// 提交分类表单
const handleCategorySubmit = async () => {
  if (!categoryFormRef.value) return

  try {
    await categoryFormRef.value.validate()
    const { id, name } = categoryForm.value
    const res = await request({
      url: id ? `/api/spot/category/${id}` : '/api/spot/category',
      method: id ? 'put' : 'post',
      data: { name }
    })

    if (res.data.code === 200) {
      ElMessage.success(id ? '更新成功' : '添加成功')
      categoryDialogVisible.value = false
      getCategories()
    } else {
      ElMessage.error(res.data.msg || (id ? '更新失败' : '添加失败'))
    }
  } catch (error) {
    console.error('提交失败:', error)
    ElMessage.error(categoryForm.value.id ? '更新失败' : '添加失败')
  }
}

// 禁用的小时
const disabledHours = () => {
  return []
}

// 禁用的分钟
const disabledMinutes = () => {
  return []
}

// 处理图片和视频路径
const getMediaUrl = (path) => {
  if (!path) return ''
  if (path.startsWith('http')) return path
  return `http://localhost:8080${path.startsWith('/') ? '' : '/'}${path}`
}

// 图片列表计算属性
const imageList = computed(() => {
  const urls = []

  // 添加已有的图片（数据库中的图片）
  if (form.value.images) {
    const dbImages = form.value.images.split(',')
    dbImages.forEach(url => {
      // 只处理非 blob URL 的图片
      if (url && !url.startsWith('blob:')) {
        urls.push({
          url: getMediaUrl(url),
          name: url.split('/').pop()
        })
      }
    })
  }

  // 添加新选择的图片（本地预览的图片）
  newImages.value.forEach(image => {
    urls.push({
      url: image.url,
      name: image.raw.name
    })
  })

  return urls
})

// 视频列表计算属性
const videoList = computed(() => {
  // 如果有新上传的视频
  if (newVideo.value) {
    return [{
      url: newVideo.value.url,
      name: newVideo.value.raw.name
    }]
  }

  // 如果有已存在的视频且不是 blob URL
  if (form.value.videoUrl && !form.value.videoUrl.startsWith('blob:')) {
    return [{
      url: getMediaUrl(form.value.videoUrl),
      name: form.value.videoUrl.split('/').pop()
    }]
  }

  return []
})

// 修改封面图展示
const coverUrl = computed(() => {
  return getMediaUrl(form.value.coverUrl)
})

// 清理函数
const cleanupFiles = () => {
  // 清理图片预览URL
  newImages.value.forEach(image => {
    if (image.url.startsWith('blob:')) {
      URL.revokeObjectURL(image.url)
    }
  })
  newImages.value = []

  // 清理视频预览URL
  if (newVideo.value && newVideo.value.url.startsWith('blob:')) {
    URL.revokeObjectURL(newVideo.value.url)
  }
  newVideo.value = null
  
  // 重置删除记录
  deletedImages.value = []
  deletedVideo.value = false
}

// 添加上传成功处理函数
const handleUploadSuccess = (response, uploadFile) => {
  if (response.code === 200) {
    // 获取上传后的文件路径
    const filePath = response.data
    
    // 更新图片列表
    const imageUrls = form.value.images ? form.value.images.split(',') : []
    imageUrls.push(filePath)
    form.value.images = imageUrls.join(',')

    // 如果没有封面图，设置第一张图片为封面
    if (!form.value.coverUrl) {
      form.value.coverUrl = filePath
    }

    ElMessage.success('上传成功')
  } else {
    ElMessage.error(response.msg || '上传失败')
  }
}

// 添加视频上传成功处理函数
const handleVideoUploadSuccess = (response, uploadFile) => {
  if (response.code === 200) {
    form.value.videoUrl = response.data
    ElMessage.success('视频上传成功')
  } else {
    ElMessage.error(response.msg || '视频上传失败')
  }
}

// 添加上传错误处理函数
const handleUploadError = (error, file) => {

  ElMessage.error('上传失败，请重试')
}

// 图片上传前的验证
const beforeImageUpload = (file) => {
 

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
getCategories()
</script>

<style lang="scss" scoped>
@import '@/styles/mixins.scss';

.spots-container {
  padding: 20px;

  .search-bar {
    margin-bottom: 20px;
  }

  .spot-info {
    display: flex;
    gap: 12px;
    align-items: flex-start;

    .image-wrapper {
      flex-shrink: 0;
      width: 120px;
      height: 80px;
      overflow: hidden;
      border-radius: 4px;

      .spot-image {
        width: 100%;
        height: 100%;
        object-fit: cover;
        cursor: pointer;
        transition: transform 0.3s;

        &:hover {
          transform: scale(1.05);
        }
      }
    }

    .info {
      flex: 1;
      min-width: 0; // 防止文字溢出

      h3 {
        margin: 0 0 8px;
        font-size: 16px;
        font-weight: 500;
        color: var(--el-text-color-primary);
      }

      p {
        margin: 0;
        font-size: 14px;
        color: var(--el-text-color-secondary);
        @include text-overflow(2); // 显示两行，超出省略
      }
    }
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
  }

  .avatar {
    width: 178px;
    height: 178px;
    display: block;
  }

  .preview-video {
    margin-top: 10px;
    max-width: 100%;
    max-height: 300px;
  }

  .upload-list {
    :deep(.el-upload--picture-card) {
      width: 100px;
      height: 100px;
      line-height: 100px;
    }

    :deep(.el-upload-list--picture-card) {
      .el-upload-list__item {
        width: 100px;
        height: 100px;
      }
    }
  }

  .category-manager {
    .header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 15px;

      h3 {
        margin: 0;
        font-size: 16px;
      }
    }
  }
}

.mx-2 {
  margin: 0 8px;
}

// 图片预览对话框样式
:deep(.preview-dialog) {
  .el-dialog__body {
    padding: 0;
    display: flex;
    justify-content: center;
    align-items: center;
    background: #000;
    min-height: 400px;
    max-height: 80vh;
    overflow: hidden;
  }

  .preview-image {
    max-width: 100%;
    max-height: 80vh;
    object-fit: contain;
  }
}

// 确保预览图片在最上层
:deep(.el-image-viewer__wrapper) {
  z-index: 3000;
}

// 图片预览遮罩层样式
:deep(.el-image-viewer__mask) {
  background-color: rgba(0, 0, 0, 0.9);
}

// 图片预览操作按钮样式
:deep(.el-image-viewer__btn) {
  opacity: 0.8;

  &:hover {
    opacity: 1;
  }
}

.upload-video {
  .el-upload__tip {
    color: var(--el-text-color-secondary);
    font-size: 12px;
    margin-top: 4px;
    line-height: 1.5;
  }
}

.video-preview {
  margin-top: 16px;
  border-radius: 4px;
  overflow: hidden;
  background-color: #000;
  max-width: 600px;

  .preview-video {
    width: 100%;
    height: auto;
    max-height: 300px;
    display: block;
  }
}

// 视频预览对话框样式
:deep(.video-preview-dialog) {
  .el-dialog__body {
    padding: 0;
    background: #000;
    display: flex;
    justify-content: center;
    align-items: center;
    min-height: 400px;
  }

  .preview-video-full {
    width: 100%;
    height: auto;
    max-height: 80vh;
    display: block;
  }
}
</style>
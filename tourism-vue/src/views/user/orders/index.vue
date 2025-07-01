<template>
  <div>
    <div class="orders-container">
      <!-- 订单状态标签页 -->
      <el-tabs v-model="activeTab" @tab-click="handleTabChange">
        <el-tab-pane label="全部订单" name="all" />
        <el-tab-pane label="待使用" name="0" />
        <el-tab-pane label="已使用" name="1" />
        <el-tab-pane label="已退款" name="2" />
        <el-tab-pane label="已取消" name="3" />
      </el-tabs>

      <!-- 订单列表 -->
      <div v-loading="loading" class="order-cards">
        <el-empty v-if="!loading && orders.length === 0" description="暂无订单" />
        
        <el-card v-for="order in orders" :key="order.id" class="order-card">
          <div class="order-header">
            <span class="order-no">订单号：{{ order.orderNo }}</span>
            <el-tag :type="getOrderStatusType(order.status)">
              {{ getOrderStatusText(order.status) }}
            </el-tag>
          </div>
          
          <div class="order-content">
            <div class="spot-info">
              <el-image :src="order.spotImage" :alt="order.spotName" class="spot-image" />
              <div class="info-right">
                <h3>{{ order.spotName }}</h3>
                <p class="visit-date">游玩日期：{{ formatDate(order.visitDate) }}</p>
                <p class="quantity">数量：{{ order.quantity }}张</p>
                <div class="price-info">
                  <span class="unit-price">¥{{ order.unitPrice }}/张</span>
                  <span class="total-price">总价：¥{{ order.totalPrice }}</span>
                </div>
              </div>
            </div>
            
            <div class="insurance-tag" v-if="order.needInsurance">
              <el-tag size="small" type="success">已购保险</el-tag>
            </div>
          </div>
          
          <div class="order-footer">
            <span class="time">{{ formatDateTime(order.createdTime) }}</span>
            <div class="actions">
              <!-- 待使用状态可以申请退款 -->
              <el-button 
                v-if="order.status === 0"
                type="warning" 
                size="small"
                @click="handleRefund(order)"
              >
                申请退款
              </el-button>
              
              <!-- 所有状态都可以查看详情 -->
              <el-button
                type="info"
                size="small"
                @click="handleDetail(order)"
              >
                订单详情
              </el-button>
              
              <!-- 已完成的订单可以删除 -->
              <el-button
                v-if="[1, 2, 3].includes(order.status)"
                type="danger"
                size="small"
                @click="handleDelete(order)"
              >
                删除订单
              </el-button>
            </div>
          </div>
        </el-card>
      </div>

      <!-- 分页 -->
      <div class="pagination">
        <el-pagination
          :current-page="page"
          :page-size="pageSize"
          :page-sizes="[10, 20, 50]"
          :total="total"
          layout="total, sizes, prev, pager, next"
          @size-change="handleSizeChange"
          @current-change="handleCurrentChange"
          @update:current-page="page = $event"
          @update:page-size="pageSize = $event"
        />
      </div>
    </div>

    <!-- 订单详情抽屉 -->
    <el-drawer
      v-model="drawer.visible"
      title="订单详情"
      size="500px"
    >
      <div v-if="drawer.order" class="order-detail">
        <div class="detail-section">
          <h4>景点信息</h4>
          <p>景点名称：{{ drawer.order.spotName }}</p>
          <p>游玩日期：{{ drawer.order.visitDate }}</p>
          <p>门票类型：{{ drawer.order.ticketType }}</p>
          <p>购买数量：{{ drawer.order.quantity }}</p>
        </div>
        
        <div class="detail-section">
          <h4>订单信息</h4>
          <p>订单编号：{{ drawer.order.orderNo }}</p>
          <p>下单时间：{{ drawer.order.createdTime }}</p>
          <p>订单状态：{{ getOrderStatusText(drawer.order.status) }}</p>
          <p>支付方式：{{ drawer.order.paymentMethod || '-' }}</p>
          <p>支付时间：{{ drawer.order.createdTime || '-' }}</p>
        </div>
        
        <div class="detail-section">
          <h4>金额信息</h4>
          <p>门票单价：¥{{ drawer.order.price }}</p>
          <p>数量：x{{ drawer.order.quantity }}</p>
          <p class="total">总计：¥{{ drawer.order.totalAmount }}</p>
        </div>
        
        <div class="detail-section">
          <h4>游客信息</h4>
          <p>联系人：{{ drawer.order.contactName }}</p>
          <p>手机号：{{ drawer.order.contactPhone }}</p>
          <p>身份证：{{ drawer.order.contactIdCard }}</p>
        </div>
      </div>
    </el-drawer>

    <!-- 退款对话框 -->
    <el-dialog
      v-model="refundDialog.visible"
      title="申请退款"
      width="400px"
    >
      <el-form :model="refundDialog.form" label-width="80px">
        <el-form-item label="退款原因" prop="reason">
          <el-select v-model="refundDialog.form.reason" placeholder="请选择退款原因">
            <el-option label="行程变更" value="行程变更" />
            <el-option label="天气原因" value="天气原因" />
            <el-option label="其他原因" value="其他原因" />
          </el-select>
        </el-form-item>
        <el-form-item label="详细说明" prop="description">
          <el-input
            type="textarea"
            v-model="refundDialog.form.description"
            rows="3"
            placeholder="请详细说明退款原因"
          />
        </el-form-item>
      </el-form>
      <template #footer>
        <div class="dialog-footer">
          <el-button @click="refundDialog.visible = false">取消</el-button>
          <el-button 
            type="primary" 
            @click="submitRefund" 
            :loading="refundDialog.submitting"
          >
            提交申请
          </el-button>
        </div>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import request from '@/utils/request'
import dayjs from 'dayjs'

// 状态
const activeTab = ref('all')
const loading = ref(false)
const page = ref(1)
const pageSize = ref(10)
const total = ref(0)
const orders = ref([])
const viewMode = ref('card')

// 抽屉状态
const drawer = reactive({
  visible: false,
  order: null
})

// 退款对话框状态
const refundDialog = reactive({
  visible: false,
  form: {
    reason: '',
    description: ''
  },
  submitting: false,
  currentOrder: null
})

// 订单状态映射
const statusMap = {
  0: { type: 'primary', text: '待使用' },
  1: { type: 'success', text: '已使用' },
  2: { type: 'info', text: '已退款' },
  3: { type: 'danger', text: '已取消' }
}

// 获取订单状态类型
const getOrderStatusType = (status) => {
  return statusMap[status]?.type || 'info'
}

// 获取订单状态文本
const getOrderStatusText = (status) => {
  return statusMap[status]?.text || '未知状态'
}

// 获取订单列表
const getOrders = async () => {
  if (loading.value) return
  
  try {
    loading.value = true
    const params = {
      page: page.value,
      pageSize: pageSize.value
    }
    
    // 如果不是全部订单，添加状态筛选
    if (activeTab.value !== 'all') {
      params.status = parseInt(activeTab.value)
    }
    
    const { data: res } = await request.get('/api/orders', { params })
    console.log('订单列表响应:', res) // 添加日志
    
    if (res.code === 200) {
      orders.value = res.data.records || []
      total.value = res.data.total || 0
    } else {
      ElMessage.error(res.message || '获取订单列表失败')
    }
  } catch (error) {
    console.error('获取订单列表失败:', error)
    ElMessage.error('获取订单列表失败')
  } finally {
    loading.value = false
  }
}

// 标签页切换
const handleTabChange = () => {
  page.value = 1
  getOrders()
}

// 分页处理
const handleSizeChange = (val) => {
  pageSize.value = val
  getOrders()
}

const handleCurrentChange = (val) => {
  page.value = val
  getOrders()
}

// 格式化日期
const formatDate = (date) => {
  return date ? dayjs(date).format('YYYY-MM-DD') : '-'
}

const formatDateTime = (datetime) => {
  return datetime ? dayjs(datetime).format('YYYY-MM-DD HH:mm:ss') : '-'
}

// 支付订单
const handlePay = async (order) => {
  try {
    const { data: res } = await request.post(`/api/orders/${order.id}/pay`)
    if (res.code === 200) {
      ElMessage.success('支付成功')
      getOrders()
    } else {
      ElMessage.error(res.message || '支付失败')
    }
  } catch (error) {
    console.error('支付失败:', error)
    ElMessage.error('支付失败')
  }
}

// 查看电子门票
const handleViewTicket = async (order) => {
  try {
    const { data: res } = await request.get(`/api/orders/${order.id}/ticket`)
    if (res.code === 200) {
      // 处理门票显示逻辑
      ElMessage.success('获取门票成功')
    } else {
      ElMessage.error(res.message || '获取门票失败')
    }
  } catch (error) {
    console.error('获取门票失败:', error)
    ElMessage.error('获取门票失败')
  }
}

// 取消订单
const handleCancel = async (order) => {
  try {
    await ElMessageBox.confirm('确定要取消该订单吗？', '提示', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    })
    
    const { data: res } = await request.post(`/api/orders/${order.id}/cancel`)
    if (res.code === 200) {
      ElMessage.success('订单已取消')
      getOrders()
    } else {
      ElMessage.error(res.message || '取消订单失败')
    }
  } catch (error) {
    if (error !== 'cancel') {
      console.error('取消订单失败:', error)
      ElMessage.error('取消订单失败')
    }
  }
}

// 评价订单
const handleComment = (order) => {
  // 实现评价逻辑
}

// 查看订单详情
const handleDetail = (order) => {
  drawer.order = order
  drawer.visible = true
}

// 处理退款
const handleRefund = (order) => {
  refundDialog.currentOrder = order
  refundDialog.form = {
    reason: '',
    description: ''
  }
  refundDialog.visible = true
}

// 提交退款申请
const submitRefund = async () => {
  if (!refundDialog.form.reason) {
    ElMessage.warning('请选择退款原因')
    return
  }
  
  try {
    refundDialog.submitting = true
    const { data: res } = await request.post(
      `/api/orders/${refundDialog.currentOrder.id}/refund`,
      refundDialog.form
    )
    
    if (res.code === 200) {
      ElMessage.success('退款申请已提交')
      refundDialog.visible = false
      getOrders() // 刷新订单列表
    } else {
      ElMessage.error(res.message || '申请退款失败')
    }
  } catch (error) {
    console.error('申请退款失败:', error)
    ElMessage.error('申请退款失败')
  } finally {
    refundDialog.submitting = false
  }
}

// 删除订单
const handleDelete = async (order) => {
  try {
    await ElMessageBox.confirm('确定要删除该订单吗？删除后将无法恢复', '提示', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    })
    
    const { data: res } = await request.delete(`/api/orders/${order.id}`)
    if (res.code === 200) {
      ElMessage.success('订单已删除')
      getOrders() // 刷新订单列表
    } else {
      ElMessage.error(res.message || '删除订单失败')
    }
  } catch (error) {
    if (error !== 'cancel') {
      console.error('删除订单失败:', error)
      ElMessage.error('删除订单失败')
    }
  }
}

// 组件挂载时获取订单列表
onMounted(() => {
  getOrders()
})
</script>

<style lang="scss" scoped>
.orders-container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 20px;
  
  // 标签页美化
  :deep(.el-tabs__header) {
    margin-bottom: 20px;
    
    .el-tabs__nav-wrap::after {
      height: 1px;
      background-color: rgba(0, 0, 0, 0.05);
    }
    
    .el-tabs__item {
      font-size: 15px;
      padding: 0 20px;
      height: 50px;
      line-height: 50px;
      font-weight: 500;
      transition: all 0.3s;
      
      &.is-active {
        color: #ff4757;
        font-weight: 600;
      }
      
      &:hover {
        color: #ff4757;
      }
    }
    
    .el-tabs__active-bar {
      background-color: #ff4757;
      height: 3px;
      border-radius: 3px;
    }
  }
  
  .order-cards {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(400px, 1fr));
    gap: 20px;
    margin-bottom: 20px;
    animation: fadeIn 0.5s ease-out;
    
    .order-card {
      background-color: #fff;
      position: relative;
      z-index: 1;
      box-shadow: 0 6px 16px rgba(0, 0, 0, 0.08);
      border-radius: 12px;
      overflow: hidden;
      transition: transform 0.3s, box-shadow 0.3s;
      border: none;
      
      &:hover {
        transform: translateY(-5px);
        box-shadow: 0 10px 25px rgba(0, 0, 0, 0.12);
      }
      
      .order-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 16px;
        padding-bottom: 12px;
        border-bottom: 1px solid #f0f2f5;
        
        .order-no {
          color: #666;
          font-size: 14px;
        }
        
        :deep(.el-tag) {
          border-radius: 20px;
          padding: 0 12px;
          font-weight: 500;
        }
      }
      
      .order-content {
        position: relative;
        
        .spot-info {
          display: flex;
          gap: 16px;
          
          .spot-image {
            width: 120px;
            height: 80px;
            border-radius: 8px;
            object-fit: cover;
            box-shadow: 0 3px 8px rgba(0, 0, 0, 0.1);
            transition: transform 0.5s;
            
            &:hover {
              transform: scale(1.05);
            }
          }
          
          .info-right {
            flex: 1;
            
            h3 {
              margin: 0 0 10px;
              font-size: 17px;
              font-weight: 600;
              color: #303133;
            }
            
            p {
              margin: 6px 0;
              color: #606266;
              font-size: 14px;
            }
            
            .price-info {
              margin-top: 10px;
              
              .unit-price {
                color: #909399;
                margin-right: 16px;
                font-size: 14px;
              }
              
              .total-price {
                color: #ff4757;
                font-weight: 600;
                font-size: 16px;
              }
            }
          }
        }
        
        .insurance-tag {
          position: absolute;
          top: 0;
          right: 0;
          
          :deep(.el-tag) {
            border-radius: 16px;
          }
        }
      }
      
      .order-footer {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-top: 16px;
        padding-top: 16px;
        border-top: 1px solid #f0f2f5;
        background-color: #fafafa;
        padding: 14px 0;
        
        .time {
          color: #909399;
          font-size: 13px;
        }
        
        .actions {
          display: flex;
          gap: 8px;
          
          :deep(.el-button) {
            border-radius: 20px;
            font-weight: 500;
            transition: all 0.3s;
            
            &:hover {
              transform: translateY(-2px);
              box-shadow: 0 4px 10px rgba(0, 0, 0, 0.1);
            }
            
            &.is-plain {
              &:hover {
                color: var(--el-color-primary);
                border-color: var(--el-color-primary);
              }
            }
            
            &.el-button--danger:hover {
              box-shadow: 0 4px 10px rgba(255, 71, 87, 0.2);
            }
            
            &.el-button--warning:hover {
              box-shadow: 0 4px 10px rgba(230, 162, 60, 0.2);
            }
            
            &.el-button--info:hover {
              box-shadow: 0 4px 10px rgba(144, 147, 153, 0.2);
            }
          }
        }
      }
    }
  }
  
  .pagination {
    margin-top: 20px;
    text-align: right;
    padding: 15px;
    background: linear-gradient(135deg, rgba(255,255,255,0.9) 0%, rgba(240,245,255,0.9) 100%);
    border-radius: 12px;
    box-shadow: 0 4px 20px rgba(0,0,0,0.05);
    backdrop-filter: blur(10px);
    
    :deep(.el-pagination) {
      .el-pagination__sizes .el-input .el-input__wrapper {
        border-radius: 20px;
      }
      
      button {
        border-radius: 50%;
        transition: all 0.3s;
        
        &:hover {
          transform: translateY(-2px);
        }
      }
      
      .el-pager li {
        border-radius: 8px;
        transition: all 0.3s;
        
        &:hover {
          transform: translateY(-2px);
        }
        
        &.is-active {
          background: linear-gradient(45deg, #ff4757, #ff6b81);
          color: white;
          font-weight: 600;
        }
      }
    }
  }
}

.order-detail {
  padding: 20px;
  
  .detail-section {
    margin-bottom: 24px;
    
    h4 {
      margin: 0 0 16px;
      padding-bottom: 10px;
      border-bottom: 1px solid #ebeef5;
      color: #303133;
      font-weight: 600;
      position: relative;
      
      &::after {
        content: '';
        position: absolute;
        left: 0;
        bottom: -1px;
        height: 3px;
        width: 40px;
        background: linear-gradient(45deg, #ff4757, #ff6b81);
        border-radius: 3px;
      }
    }
    
    p {
      margin: 10px 0;
      color: #606266;
      font-size: 15px;
      display: flex;
      justify-content: space-between;
      
      &.total {
        color: #ff4757;
        font-weight: 600;
        font-size: 16px;
        margin-top: 15px;
        padding-top: 10px;
        border-top: 1px dashed #ebeef5;
      }
    }
  }
}

:deep(.el-drawer__header) {
  padding: 20px;
  margin-bottom: 0;
  border-bottom: 1px solid #f0f2f5;
  
  .el-drawer__title {
    font-size: 18px;
    font-weight: 600;
    color: #303133;
  }
}

:deep(.el-dialog__header) {
  padding: 20px;
  margin: 0;
  border-bottom: 1px solid #f0f2f5;
  
  .el-dialog__title {
    font-size: 18px;
    font-weight: 600;
    color: #303133;
  }
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
</style> 
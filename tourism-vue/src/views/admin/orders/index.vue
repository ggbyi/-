<template>
  <div class="orders-container">


    <!-- 搜索栏 -->
    <div class="search-bar">
      <el-form :inline="true" :model="searchForm">
        <el-form-item label="订单号">
          <el-input v-model="searchForm.orderNo" placeholder="请输入订单号" clearable />
        </el-form-item>
        <el-form-item label="景点名称">
          <el-input v-model="searchForm.spotName" placeholder="请输入景点名称" clearable />
        </el-form-item>
        <el-form-item label="用户ID">
          <el-input v-model="searchForm.userId" placeholder="请输入用户ID" clearable />
        </el-form-item>
        <el-form-item label="订单状态">
          <el-select v-model="searchForm.status" placeholder="请选择状态" clearable>
            <el-option label="待使用" :value="0" />
            <el-option label="已使用" :value="1" />
            <el-option label="已退款" :value="2" />
            <el-option label="已取消" :value="3" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="handleSearch">查询</el-button>
          <el-button @click="resetSearch">重置</el-button>
        </el-form-item>
      </el-form>
      
      <el-button-group>
        <el-button @click="exportOrders">
          <el-icon><Download /></el-icon>导出
        </el-button>
        <el-button @click="printOrders">
          <el-icon><Printer /></el-icon>打印
        </el-button>
      </el-button-group>
    </div>

    <!-- 订单列表 -->
    <el-card>
      <el-table
        v-loading="loading"
        :data="orderList"
        border
        style="width: 100%"
      >
        <el-table-column prop="orderNo" label="订单号" width="180" />
        <el-table-column label="景点信息" min-width="300">
          <template #default="{ row }">
            <div class="spot-info">
              <el-image :src="row.spotImage" class="spot-image" />
              <div class="info">
                <div class="spot-name">{{ row.spotName }}</div>
                <div class="visit-date">游玩日期：{{ formatDate(row.visitDate) }}</div>
              </div>
            </div>
          </template>
        </el-table-column>
        <el-table-column prop="userId" label="用户ID" width="100" />
        <el-table-column label="数量/价格" width="150">
          <template #default="{ row }">
            <div>{{ row.quantity }}张</div>
            <div class="price">¥{{ row.totalPrice }}</div>
          </template>
        </el-table-column>
        <el-table-column prop="status" label="状态" width="100">
          <template #default="{ row }">
            <el-tag :type="getOrderStatusType(row.status)">
              {{ getOrderStatusText(row.status) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="createdTime" label="创建时间" width="180">
          <template #default="{ row }">
            {{ formatDateTime(row.createdTime) }}
          </template>
        </el-table-column>
        <el-table-column label="操作" width="180" fixed="right">
          <template #default="{ row }">
            <el-button 
              type="primary" 
              size="small" 
              @click="handleViewDetail(row)"
            >
              详情
            </el-button>
            <el-button
              type="danger"
              size="small"
              @click="handleDelete(row)"
            >
              删除
            </el-button>
          </template>
        </el-table-column>
      </el-table>

      <!-- 分页 -->
      <div class="pagination">
        <el-pagination
          v-model:current-page="page"
          v-model:page-size="pageSize"
          :page-sizes="[5,10, 20, 50]"
          :total="total"
          layout="total, sizes, prev, pager, next"
          @size-change="handleSizeChange"
          @current-change="handleCurrentChange"
        />
      </div>
    </el-card>

    <!-- 订单详情抽屉 -->
    <el-drawer
      v-model="drawer.visible"
      title="订单详情"
      size="500px"
    >
      <div v-if="drawer.order" class="order-detail">
        <div class="detail-section">
          <h4>景点信息</h4>
          <div class="spot-info">
            <el-image :src="drawer.order.spotImage" class="spot-image" />
            <div class="info">
              <p>景点名称：{{ drawer.order.spotName }}</p>
              <p>游玩日期：{{ formatDate(drawer.order.visitDate) }}</p>
              <p>购买数量：{{ drawer.order.quantity }}张</p>
            </div>
          </div>
        </div>
        
        <div class="detail-section">
          <h4>订单信息</h4>
          <p>订单编号：{{ drawer.order.orderNo }}</p>
          <p>用户ID：{{ drawer.order.userId }}</p>
          <p>创建时间：{{ formatDateTime(drawer.order.createdTime) }}</p>
          <p>订单状态：{{ getOrderStatusText(drawer.order.status) }}</p>
          <p>支付时间：{{ formatDateTime(drawer.order.payTime) || '-' }}</p>
        </div>
        
        <div class="detail-section">
          <h4>金额信息</h4>
          <p>单价：¥{{ drawer.order.unitPrice }}</p>
          <p>数量：x{{ drawer.order.quantity }}</p>
          <p>保险：{{ drawer.order.needInsurance ? '已购买' : '未购买' }}</p>
          <p class="total">总计：¥{{ drawer.order.totalPrice }}</p>
        </div>
      </div>
    </el-drawer>

    <!-- 处理退款对话框 -->
    <el-dialog
      v-model="refundDialog.visible"
      title="处理退款申请"
      width="400px"
    >
      <div v-if="refundDialog.order">
        <p>订单号：{{ refundDialog.order.orderNo }}</p>
        <p>退款金额：¥{{ refundDialog.order.totalPrice }}</p>
        <p>申请原因：{{ refundDialog.order.refundInfo?.reason }}</p>
        <p>详细说明：{{ refundDialog.order.refundInfo?.description }}</p>
        
        <el-form :model="refundDialog.form" label-width="80px" class="mt-4">
          <el-form-item label="处理结果">
            <el-radio-group v-model="refundDialog.form.status">
              <el-radio :label="1">同意退款</el-radio>
              <el-radio :label="2">拒绝退款</el-radio>
            </el-radio-group>
          </el-form-item>
          <el-form-item label="处理备注">
            <el-input
              type="textarea"
              v-model="refundDialog.form.remark"
              rows="3"
              placeholder="请输入处理备注"
            />
          </el-form-item>
        </el-form>
      </div>
      <template #footer>
        <div class="dialog-footer">
          <el-button @click="refundDialog.visible = false">取消</el-button>
          <el-button 
            type="primary" 
            @click="submitProcessRefund"
            :loading="refundDialog.submitting"
          >
            确认
          </el-button>
        </div>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { 
  Download,
  Printer,
  Wallet,
  ShoppingCart,
  Money,
  Warning
} from '@element-plus/icons-vue'
import request from '@/utils/request'
import dayjs from 'dayjs'



// 搜索表单
const searchForm = reactive({
  orderNo: '',
  spotName: '',
  userId: '',
  status: null
})

// 分页参数
const page = ref(1)
const pageSize = ref(5)
const total = ref(0)

// 订单列表
const loading = ref(false)
const orderList = ref([])

// 订单详情抽屉
const drawer = reactive({
  visible: false,
  order: null
})

// 退款处理对话框
const refundDialog = reactive({
  visible: false,
  submitting: false,
  order: null,
  form: {
    status: 1,
    remark: ''
  }
})

// 获取订单列表
const getOrderList = async () => {
  if (loading.value) return
  
  try {
    loading.value = true
    const params = {
      page: page.value,
      pageSize: pageSize.value,
      ...searchForm
    }
    
    const { data: res } = await request.get('/api/orders/admin/list', { params })
    
    if (res.code === 200) {
      orderList.value = res.data.records || []
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

// 查看订单详情
const handleViewDetail = (order) => {
  drawer.order = order
  drawer.visible = true
}

// 删除订单
const handleDelete = async (order) => {
  try {
    await ElMessageBox.confirm('确定要删除该订单吗？删除后不可恢复', '提示', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    })
    
    const { data: res } = await request.delete(`/api/orders/${order.id}`)
    if (res.code === 200) {
      ElMessage.success('删除成功')
      getOrderList()
    } else {
      ElMessage.error(res.message || '删除失败')
    }
  } catch (error) {
    if (error !== 'cancel') {
      console.error('删除订单失败:', error)
      ElMessage.error('删除订单失败')
    }
  }
}

// 导出订单
const exportOrders = () => {
  // TODO: 实现导出功能
  ElMessage.success('导出成功')
}

// 打印订单
const printOrders = () => {
  // TODO: 实现打印功能
  window.print()
}

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

// 获取支付方式标签类型
const getPaymentTagType = (method) => {
  const map = {
    WECHAT: 'success',
    ALIPAY: 'primary',
    UNIONPAY: 'warning'
  }
  return map[method] || 'info'
}

// 获取支付方式文本
const getPaymentText = (method) => {
  const map = {
    WECHAT: '微信支付',
    ALIPAY: '支付宝',
    UNIONPAY: '银联'
  }
  return map[method] || method
}

// 获取时间线项目类型
const getTimelineItemType = (status) => {
  const map = {
    UNPAID: 'warning',
    PAID: 'primary',
    COMPLETED: 'success',
    CANCELLED: 'info',
    REFUNDED: 'danger'
  }
  return map[status] || 'info'
}

// 获取时间线项目颜色
const getTimelineItemColor = (status) => {
  const map = {
    UNPAID: '#e6a23c',
    PAID: '#409eff',
    COMPLETED: '#67c23a',
    CANCELLED: '#909399',
    REFUNDED: '#f56c6c'
  }
  return map[status]
}

// 搜索
const handleSearch = () => {
  page.value = 1
  getOrderList()
}

// 重置搜索
const resetSearch = () => {
  Object.keys(searchForm).forEach(key => {
    searchForm[key] = ''
  })
  page.value = 1
  getOrderList()
}

// 分页处理
const handleSizeChange = (val) => {
  pageSize.value = val
  getOrderList()
}

const handleCurrentChange = (val) => {
  page.value = val
  getOrderList()
}

// 格式化函数
const formatDate = (date) => {
  return date ? dayjs(date).format('YYYY-MM-DD') : '-'
}

const formatDateTime = (datetime) => {
  return datetime ? dayjs(datetime).format('YYYY-MM-DD HH:mm:ss') : '-'
}

// 处理退款
const handleProcessRefund = async (order) => {
  try {
    const { data: res } = await request.post(`/api/orders/${order.id}/refund`, {
      status: refundDialog.form.status,
      remark: refundDialog.form.remark
    })
    
    if (res.code === 200) {
      ElMessage.success('处理成功')
      refundDialog.visible = false
      getOrderList()
    } else {
      ElMessage.error(res.message || '处理失败')
    }
  } catch (error) {
    console.error('处理退款失败:', error)
    ElMessage.error('处理退款失败')
  }
}

// 组件挂载时获取订单列表
onMounted(() => {
  getOrderList()
})
</script>

<style lang="scss" scoped>
.orders-container {
  padding: 20px;
  
  .stat-cards {
    margin-bottom: 20px;
    
    .stat-card {
      background: #fff;
      padding: 20px;
      border-radius: 8px;
      display: flex;
      align-items: center;
      gap: 16px;
      transition: all 0.3s;
      
      &:hover {
        transform: translateY(-4px);
        box-shadow: 0 4px 12px rgba(0,0,0,0.1);
      }
      
      .icon-wrapper {
        width: 48px;
        height: 48px;
        border-radius: 8px;
        display: flex;
        align-items: center;
        justify-content: center;
        
        .el-icon {
          font-size: 24px;
          color: #fff;
        }
      }
      
      .content {
        flex: 1;
        
        .title {
          font-size: 14px;
          color: #909399;
          margin-bottom: 8px;
        }
        
        .value {
          font-size: 24px;
          font-weight: bold;
          margin-bottom: 8px;
        }
        
        .trend {
          font-size: 13px;
          color: #909399;
          
          span {
            &.up {
              color: #67c23a;
            }
            
            &.down {
              color: #f56c6c;
            }
          }
        }
      }
      
      &.primary {
        .icon-wrapper {
          background: var(--el-color-primary);
        }
        .value {
          color: var(--el-color-primary);
        }
      }
      
      &.success {
        .icon-wrapper {
          background: var(--el-color-success);
        }
        .value {
          color: var(--el-color-success);
        }
      }
      
      &.warning {
        .icon-wrapper {
          background: var(--el-color-warning);
        }
        .value {
          color: var(--el-color-warning);
        }
      }
      
      &.danger {
        .icon-wrapper {
          background: var(--el-color-danger);
        }
        .value {
          color: var(--el-color-danger);
        }
      }
    }
  }
  
  .search-bar {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 20px;
  }
  
  .order-info {
    display: flex;
    gap: 12px;
    
    .spot-image {
      width: 80px;
      height: 60px;
      border-radius: 4px;
    }
    
    .info {
      .order-no {
        font-size: 14px;
        color: #909399;
        margin-bottom: 4px;
      }
      
      .spot-name {
        font-size: 15px;
        font-weight: 500;
        margin-bottom: 8px;
      }
      
      .user-info {
        display: flex;
        align-items: center;
        gap: 8px;
        font-size: 13px;
        color: #606266;
      }
    }
  }
  
  .amount-info {
    .quantity {
      font-size: 13px;
      color: #909399;
      margin-bottom: 4px;
    }
    
    .amount {
      font-size: 15px;
      font-weight: 500;
      color: #f56c6c;
    }
  }
  
  .pagination {
    margin-top: 20px;
    text-align: right;
  }
}

.order-detail {
  padding: 20px;
  
  .timeline-section,
  .info-section,
  .visitor-section,
  .refund-section {
    margin-bottom: 32px;
    
    h4 {
      margin: 0 0 16px;
      padding-bottom: 8px;
      border-bottom: 1px solid #ebeef5;
      font-size: 16px;
    }
  }
  
  .status-desc {
    font-size: 13px;
    color: #909399;
    margin-top: 4px;
  }
  
  .info-grid {
    display: grid;
    grid-template-columns: repeat(2, 1fr);
    gap: 16px;
    
    .info-item {
      .label {
        color: #909399;
        margin-right: 8px;
      }
      
      .value {
        &.amount {
          color: #f56c6c;
          font-weight: 500;
        }
      }
    }
  }
}
</style> 
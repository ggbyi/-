<template>
  <div class="spot-detail">
    <!-- 返回按钮 -->
    <div class="back-btn" @click="$router.back()">
      <el-icon><ArrowLeft /></el-icon>
    </div>

    <!-- 媒体展示区 -->
    <div class="media-section">
      <!-- 视频播放器 -->
      <video
        v-if="spot.videoUrl"
        class="spot-video"
        :src="getMediaUrl(spot.videoUrl)"
        controls
        autoplay
      />
      
      <!-- 图片轮播 -->
      <!-- 图片轮播 -->
      <el-carousel
          v-else
          height="500px"
          indicator-position="outside"
          :interval="4000"
          :autoplay="true"
      >
        <el-carousel-item v-for="url in imageList" :key="url">
          <el-image
              :src="getMediaUrl(url)"
              fit="cover"
              class="carousel-image"
              @error="handleImageError"
          />
        </el-carousel-item>
      </el-carousel>
    </div>

    <!-- 景点信息 -->
    <div class="spot-info">
      <div class="header">
        <h1>{{ spot.name }}</h1>
        <div class="actions">
          <el-button
            :type="spot.isLiked ? 'primary' : 'default'"
            @click="handleLike"
          >
            <el-icon><Star /></el-icon>
            {{ spot.likeCount || 0 }}
          </el-button>
          <el-button
            :type="spot.isFavorited ? 'primary' : 'default'"
            @click="handleFavorite"
          >
            <el-icon><Collection /></el-icon>
            收藏
          </el-button>
          <el-button type="primary" @click="showTicketDrawer">
            <el-icon><Ticket /></el-icon>
            购票
          </el-button>
        </div>
      </div>

      <div class="basic-info">
        <div class="info-item">
          <el-icon><Location /></el-icon>
          <span>{{ spot.location }}</span>
        </div>
        <div class="info-item">
          <el-icon><Timer /></el-icon>
          <span>营业时间：{{ spot.openTime }} - {{ spot.closeTime }}</span>
        </div>
        <div class="info-item">
          <el-icon><Ticket /></el-icon>
          <span>门票：¥{{ spot.price }}</span>
        </div>
      </div>

      <div class="description">
        <h2>景点介绍</h2>
        <p>{{ spot.description }}</p>
      </div>

      <div v-if="spot.notice" class="notice">
        <h2>游玩须知</h2>
        <p>{{ spot.notice }}</p>
      </div>

      <div v-if="spot.traffic" class="traffic">
        <h2>交通指南</h2>
        <p>{{ spot.traffic }}</p>
      </div>
    </div>

    <!-- 底部购票按钮 -->
    <div class="bottom-bar">
      <el-button type="primary" @click="showTicketDrawer" class="buy-btn">
        立即购票
      </el-button>
    </div>

    <!-- 购票抽屉 -->
    <el-drawer
      v-model="ticketDrawer"
      direction="bottom"
      size="auto"
      :with-header="false"
      custom-class="ticket-drawer"
    >
      <div class="drawer-content">
        <div class="drawer-header">
          <h3>门票预订</h3>
          <el-icon class="close-btn" @click="ticketDrawer = false"><Close /></el-icon>
        </div>

        <div class="ticket-info">
          <div class="price-info">
            <span class="label">门票价格</span>
            <span class="price">¥{{ spot.price }}</span>
          </div>
          <div class="stock-info">
            <span class="label">剩余数量</span>
            <span class="stock">{{ spot.stock || '充足' }}</span>
          </div>
        </div>

        <el-form :model="ticketForm" label-width="80px" class="ticket-form">
          <el-form-item label="游玩日期">
            <el-date-picker
              v-model="ticketForm.visitDate"
              type="date"
              placeholder="选择游玩日期"
              :disabled-date="disabledDate"
              style="width: 100%"
            />
          </el-form-item>

          <el-form-item label="购票数量">
            <el-input-number
              v-model="ticketForm.quantity"
              :min="1"
              :max="10"
              @change="calculateTotal"
              style="width: 120px"
            />
          </el-form-item>

          <el-form-item label="旅游保险">
            <el-checkbox v-model="ticketForm.needInsurance" @change="calculateTotal">
              添加旅游保险 (¥{{ insurancePrice }}/人)
            </el-checkbox>
          </el-form-item>
        </el-form>

        <div class="total-section">
          <span class="label">总价</span>
          <span class="total-price">¥{{ totalPrice }}</span>
        </div>

        <div class="payment-section">
          <div class="section-title">支付方式</div>
          <div class="payment-methods">
            <div 
              class="payment-method" 
              :class="{ active: payMethod === 'wechat' }"
              @click="payMethod = 'wechat'"
            >
              <img src="@/assets/payment/wechat.svg" alt="微信支付">
              <span>微信支付</span>
            </div>
            <div 
              class="payment-method"
              :class="{ active: payMethod === 'alipay' }"
              @click="payMethod = 'alipay'"
            >
              <img src="@/assets/payment/alipay.svg" alt="支付宝">
              <span>支付宝</span>
            </div>
          </div>
        </div>

        <div class="drawer-footer">
          <el-button 
            type="primary" 
            @click="handleSubmitOrder" 
            :loading="submitting"
            class="submit-btn"
          >
            立即支付 ¥{{ totalPrice }}
          </el-button>
        </div>
      </div>
    </el-drawer>

    <!-- 支付二维码弹窗 -->
    <el-dialog
      v-model="qrCodeVisible"
      :title="payMethod === 'wechat' ? '微信扫码支付' : '支付宝扫码支付'"
      width="300px"
      center
      :show-close="false"
      class="qrcode-dialog"
    >
      <div class="qrcode-content">
        <div class="amount">¥{{ totalPrice }}</div>
        <img :src="qrCodeUrl" alt="支付二维码" class="qrcode">
        <div class="payment-type">
          {{ payMethod === 'wechat' ? '请使用微信扫码支付' : '请使用支付宝扫码支付' }}
        </div>
      </div>
      <template #footer>
        <div class="dialog-footer">
          <el-button @click="handleCancelPay">取消支付</el-button>
          <el-button type="primary" @click="handlePaySuccess">
            支付完成
          </el-button>
        </div>
      </template>
    </el-dialog>

    <!-- 地图导航部分 -->
    <el-card v-if="spot.longitude && spot.latitude" class="map-card">
      <template #header>
        <div class="card-header">
          <h3>位置导航</h3>
          <el-button type="primary" @click="showNavigationDialog">
            <el-icon><Location /></el-icon>
            开始导航
          </el-button>
        </div>
      </template>
      
      <!-- 地图容器 -->
      <div ref="mapContainer" class="map-container"></div>
    </el-card>

    <!-- 导航对话框 -->
    <el-dialog
      v-model="navigationVisible"
      title="导航"
      width="80%"
      :destroy-on-close="true"
    >
      <div class="navigation-content">
        <!-- 导航选项 -->
        <div class="nav-options">
          <el-radio-group v-model="navigationMode">
            <el-radio-button label="drive">驾车</el-radio-button>
            <el-radio-button label="walk">步行</el-radio-button>
            <el-radio-button label="bus">公交</el-radio-button>
            <el-radio-button label="ride">骑行</el-radio-button>
          </el-radio-group>
        </div>

        <!-- 地图容器 -->
        <div ref="navigationMapContainer" class="navigation-map"></div>

        <!-- 路线详情面板 -->
        <div id="panel" class="route-panel"></div>

        <!-- 路线信息 -->
        <div v-if="routeInfo" class="route-info">
          <div class="info-item">
            <span class="label">距离：</span>
            <span class="value">{{ routeInfo.distance }}</span>
          </div>
          <div class="info-item">
            <span class="label">预计时间：</span>
            <span class="value">{{ routeInfo.duration }}</span>
          </div>
        </div>
      </div>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, onMounted, computed, onUnmounted, watch, nextTick } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { ArrowLeft, Star, Collection, Location, Timer, Ticket, Close } from '@element-plus/icons-vue'
import request from '@/utils/request'

const route = useRoute()
const router = useRouter()

const spot = ref({
  id: null,
  name: '',
  longitude: null,
  latitude: null,
  location: '',
  // ... 其他字段
})
const loading = ref(false)


// 获取景点详情
const getSpotDetail = async () => {
  try {
    loading.value = true;
    const { data: res } = await request.get(`/api/spots/${route.params.id}`);
    if (res.code === 200) {

      spot.value = res.data;

      // 如果景点有经纬度，直接初始化地图
      if (spot.value.longitude && spot.value.latitude) {
        await initMap();
      } else if (spot.value.location) {
        // 如果没有经纬度但有地址，则使用地址解析获取经纬度
        await geocodeAddress(spot.value.location);
      } else {
        console.warn('景点缺少位置信息');
      }
    } else {
      ElMessage.error(res.message || '获取景点详情失败');
    }
  } catch (error) {
    console.error('获取景点详情失败:', error);
    ElMessage.error('获取景点详情失败');
  } finally {
    loading.value = false;
  }
};

// 地理编码：根据地址获取经纬度
const geocodeAddress = async (address) => {
  const geocoder = new AMap.Geocoder();
  try {
    const result = await new Promise((resolve, reject) => {
      geocoder.getLocation(address, (status, res) => {
        if (status === 'complete' && res.geocodes && res.geocodes.length > 0) {
          resolve(res.geocodes[0].location); // 返回经纬度
        } else {
          reject('无法获取地址的经纬度');
        }
      });
    });

    if (result) {
      // 更新景点的经纬度信息
      spot.value.latitude = result.lat;
      spot.value.longitude = result.lng;
      // 初始化地图
      await initMap();
    }
  } catch (error) {
    console.error('地址解析失败:', error);
    ElMessage.error('地址解析失败，无法获取位置信息');
  }
};


// 处理点赞
const handleLike = async () => {
  try {
    const { data: res } = await request.post(`/api/spots/${spot.value.id}/like`)
    if (res.code === 200) {
      spot.value.isLiked = !spot.value.isLiked
      spot.value.likeCount = spot.value.isLiked
        ? (spot.value.likeCount || 0) + 1
        : (spot.value.likeCount || 1) - 1
      ElMessage.success(spot.value.isLiked ? '点赞成功' : '已取消点赞')
    }
  } catch (error) {
    console.error('操作失败:', error)
    ElMessage.error('操作失败')
  }
}

// 处理收藏
const handleFavorite = async () => {
  try {
    const { data: res } = await request.post(`/api/spots/${spot.value.id}/favorite`)
    if (res.code === 200) {
      spot.value.isFavorited = !spot.value.isFavorited
      ElMessage.success(spot.value.isFavorited ? '收藏成功' : '已取消收藏')
    }
  } catch (error) {
    console.error('操作失败:', error)
    ElMessage.error('操作失败')
  }
}

// 获取媒体URL
const getMediaUrl = (url) => {
  if (!url) return ''
  if (url.startsWith('http')) return url
  return `${import.meta.env.VITE_API_URL}${url}`
}

// 保险价格
const insurancePrice = 20

// 购票表单
const ticketForm = ref({
  visitDate: '',
  quantity: 1,
  needInsurance: false
})

// 提交状态
const submitting = ref(false)

// 计算总价
const totalPrice = computed(() => {
  const ticketTotal = (spot.value.price || 0) * ticketForm.value.quantity
  const insuranceTotal = ticketForm.value.needInsurance ? insurancePrice * ticketForm.value.quantity : 0
  return ticketTotal + insuranceTotal
})

// 禁用的日期（今天之前的日期）
const disabledDate = (time) => {
  return time.getTime() < Date.now() - 8.64e7
}

// 计算总价
const calculateTotal = () => {
  // 自动触发计算属性
}

// 支付方式
const payMethod = ref('wechat')

// 二维码弹窗
const qrCodeVisible = ref(false)
const qrCodeUrl = ref('')
const orderId = ref(null)

// 提交订单
const handleSubmitOrder = async () => {
  if (!ticketForm.value.visitDate) {
    ElMessage.warning('请选择游玩日期')
    return
  }

  try {
    submitting.value = true
    // 1. 先创建订单
    const { data: res } = await request.post('/api/orders', {
      spotId: spot.value.id,
      visitDate: ticketForm.value.visitDate,
      quantity: ticketForm.value.quantity,
      needInsurance: ticketForm.value.needInsurance,
      totalPrice: totalPrice.value,
      payMethod: payMethod.value
    })

    if (res.code === 200) {
      orderId.value = res.data.orderId
      ticketDrawer.value = false
      // 2. 显示支付二维码
      showPaymentQRCode()
    } else {
      ElMessage.error(res.message || '创建订单失败')
    }
  } catch (error) {
    console.error('创建订单失败:', error)
    ElMessage.error('创建订单失败')
  } finally {
    submitting.value = false
  }
}

// 显示支付二维码
const showPaymentQRCode = async () => {
  try {
    // 生成支付二维码
    const qrRes = await request.post(`/api/orders/${orderId.value}/pay`, {
      payMethod: payMethod.value
    })

    if (qrRes.data.code === 200) {
      qrCodeUrl.value = qrRes.data.data.qrCodeUrl
      qrCodeVisible.value = true
      // 开始轮询订单状态
      startCheckOrderStatus()
    } else {
      ElMessage.error(qrRes.data.message || '获取支付二维码失败')
    }
  } catch (error) {
    console.error('获取支付二维码失败:', error)
    ElMessage.error('获取支付二维码失败')
  }
}

// 轮询检查订单状态
let statusCheckTimer = null
const startCheckOrderStatus = () => {
  statusCheckTimer = setInterval(async () => {
    try {
      const { data: res } = await request.get(`/api/orders/${orderId.value}/status`)
      if (res.code === 200 && res.data.status === 1) { // 支付成功
        handlePaySuccess()
      }
    } catch (error) {
      console.error('检查订单状态失败:', error)
    }
  }, 3000)
}

// 取消支付
const handleCancelPay = () => {
  clearInterval(statusCheckTimer)
  qrCodeVisible.value = false
  ElMessage.warning('取消支付')
}

// 支付成功
const handlePaySuccess = async () => {
  clearInterval(statusCheckTimer)
  qrCodeVisible.value = false
  qrCodeUrl.value = ''
  ElMessage.success('支付成功')
  // 跳转到订单详情页
  router.push(`/user/orders`)
}

// 组件销毁时清除定时器
onUnmounted(() => {
  clearInterval(statusCheckTimer)
})

// 抽屉显示状态
const ticketDrawer = ref(false)

// 显示购票抽屉
const showTicketDrawer = () => {
  ticketDrawer.value = true
}

// 地图相关的 ref
const mapContainer = ref(null)
const navigationMapContainer = ref(null)

// 地图实例
let map = null
let navigationMap = null

// 导航相关的响应式数据
const navigationVisible = ref(false)
const navigationMode = ref('drive')
const routeInfo = ref(null)
const currentLocation = ref(null)

// 初始化地图
const initMap = async () => {
  await nextTick()
  try {
    map = new AMap.Map(mapContainer.value, {
      zoom: 15,
      center: [Number(spot.value.longitude), Number(spot.value.latitude)]
    })

    // 添加景点标记
    new AMap.Marker({
      position: [Number(spot.value.longitude), Number(spot.value.latitude)],
      title: spot.value.name,
      map: map
    })
  } catch (error) {
    console.error('初始化地图失败:', error)
  }
}

// 获取当前位置
const getCurrentPosition = () => {
  return new Promise((resolve, reject) => {
    // 先尝试使用浏览器定位
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        (position) => {
          // 浏览器定位成功
          resolve({
            position: {
              lng: position.coords.longitude,
              lat: position.coords.latitude
            }
          })
        },
        (error) => {
          // 浏览器定位失败，使用高德定位
          useAMapGeolocation(resolve, reject)
        },
        {
          enableHighAccuracy: true,
          timeout: 5000,
          maximumAge: 0
        }
      )
    } else {
      // 不支持浏览器定位，使用高德定位
      useAMapGeolocation(resolve, reject)
    }
  })
}

// 使用高德地图定位
const useAMapGeolocation = (resolve, reject) => {
  AMap.plugin('AMap.Geolocation', () => {
    const geolocation = new AMap.Geolocation({
      enableHighAccuracy: true,    // 使用高精度定位
      timeout: 10000,              // 超时时间
      GeoLocationFirst: true,      // 优先使用H5定位
      maximumAge: 0,               // 禁止缓存
      convert: true,               // 自动偏移坐标
      needAddress: true,           // 需要详细地址信息
      useNative: true              // 使用系统定位
    })

    geolocation.getCurrentPosition((status, result) => {
      if (status === 'complete') {
        resolve(result)
      } else {
        reject(new Error('获取位置失败：' + result.message))
      }
    })
  })
}

// 显示导航对话框
const showNavigationDialog = async () => {
  try {
    navigationVisible.value = true;
    await nextTick();

    // 初始化导航地图
    navigationMap = new AMap.Map(navigationMapContainer.value, {
      zoom: 12,
      center: [Number(spot.value.longitude), Number(spot.value.latitude)]
    });

    // 获取当前位置
    const position = await getCurrentPosition();
    currentLocation.value = position.position;

    // 规划路线
    planRoute();
  } catch (error) {
    console.error('初始化导航失败:', error);
    ElMessage.error('无法获取您的位置，请检查定位权限');
  }
};

// 规划路线
const planRoute = () => {
  if (!currentLocation.value) {
    ElMessage.warning('请先获取位置信息');
    return;
  }

  // 清除已有路线
  navigationMap.clearMap();

  // 添加起点标记
  const startMarker = new AMap.Marker({
    position: [currentLocation.value.lng, currentLocation.value.lat],
    title: '当前位置',
    icon: 'https://webapi.amap.com/theme/v1.3/markers/n/start.png',
    map: navigationMap
  });

  // 添加终点标记
  const endMarker = new AMap.Marker({
    position: [Number(spot.value.longitude), Number(spot.value.latitude)],
    title: spot.value.name,
    icon: 'https://webapi.amap.com/theme/v1.3/markers/n/end.png',
    map: navigationMap
  });

  // 设置起终点
  const startPoint = new AMap.LngLat(currentLocation.value.lng, currentLocation.value.lat);
  const endPoint = new AMap.LngLat(Number(spot.value.longitude), Number(spot.value.latitude));

  console.log('起点:', startPoint);
  console.log('终点:', endPoint);

  // 根据导航方式选择对应的路线规划插件
  let plannerType;
  switch (navigationMode.value) {
    case 'drive':
      plannerType = 'Driving';
      break;
    case 'walk':
      plannerType = 'Walking';
      break;
    case 'bus':
      plannerType = 'Transfer';
      break;
    case 'ride':
      plannerType = 'Riding';
      break;
    default:
      plannerType = 'Driving';
  }

  // 使用选择的导航方式
  AMap.plugin([`AMap.${plannerType}`], () => {
    const planner = new AMap[plannerType]({
      map: navigationMap,
      panel: 'panel'  // 路线详情面板的容器ID
    });

    // 开始路线规划
    planner.search(startPoint, endPoint, (status, result) => {
      console.log('status:', status);
      console.log('result:', result);
      if (status === 'complete' && result.routes && result.routes.length > 0) {
        const route = result.routes[0];
        routeInfo.value = {
          distance: (route.distance / 1000).toFixed(1) + 'km',
          duration: Math.ceil(route.time / 60) + '分钟'
        };
        navigationMap.setFitView();
      } else {
        // 根据不同错误类型显示不同的错误提示
        if (result === 'NO_CITY') {
          ElMessage.error('未找到合适的城市，请检查起点和终点');
        } else if (result === 'OVER_DIRECTION_RANGE') {
          ElMessage.error('超出导航范围，请选择其他地点');
        } else {
          ElMessage.error('路线规划失败，请重试');
        }
      }
    });
  });
};

// 监听导航方式变化时重新规划路线
watch(navigationMode, () => {
  if (currentLocation.value) {
    planRoute();
  }
});

// 组件挂载时获取数据
onMounted(() => {
  getSpotDetail()
})

// 组件卸载时清理
onUnmounted(() => {
  if (map) {
    map.destroy()
    map = null
  }
  if (navigationMap) {
    navigationMap.destroy()
    navigationMap = null
  }
})

const imageList = computed(() => {
  if (!spot.value.images) return []
  return spot.value.images.split(',')
})

// 处理图片加载错误
const handleImageError = () => {
  ElMessage.error('图片加载失败，请稍后重试。');
}
</script>

<style lang="scss" scoped>
@use '@/styles/mixins.scss' as *; // 确保使用了正确的路径

.some-class {
  @include text-overflow(2); // 使用 mixin
}
.spot-detail {
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
    background: rgba(0, 0, 0, 0.5);
    color: #fff;
    display: flex;
    align-items: center;
    justify-content: center;
    cursor: pointer;
    transition: all 0.3s;

    &:hover {
      background: rgba(0, 0, 0, 0.7);
    }
  }

  .media-section {
    height: 500px;
    background: #000;
    position: relative;

    .spot-video {
      width: 100%;
      height: 100%;
      object-fit: contain;
    }

    .carousel-image {
      width: 100%;
      height: 100%;
      object-fit: cover;
    }
  }

  .spot-info {
    padding: 20px;
    max-width: 1200px;
    margin: 0 auto;

    .header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 20px;

      h1 {
        margin: 0;
        font-size: 24px;
        color: #333;
      }

      .actions {
        display: flex;
        gap: 12px;
      }
    }

    .basic-info {
      display: flex;
      flex-wrap: wrap;
      gap: 20px;
      margin-bottom: 30px;
      padding: 15px;
      background: #f8f8f8;
      border-radius: 8px;

      .info-item {
        display: flex;
        align-items: center;
        gap: 8px;
        color: #666;

        .el-icon {
          font-size: 18px;
        }
      }
    }

    .description, .notice, .traffic {
      margin-bottom: 30px;

      h2 {
        font-size: 18px;
        color: #333;
        margin-bottom: 12px;
      }

      p {
        color: #666;
        line-height: 1.6;
        margin: 0;
        white-space: pre-wrap;
      }
    }
  }

  .ticket-section {
    display: none;
  }
}

// 轮播图样式优化
:deep(.el-carousel__indicators) {
  bottom: -30px;
}

:deep(.el-carousel__indicator) {
  .el-carousel__button {
    width: 30px;
    border-radius: 3px;
  }
}

// 底部购票按钮
.bottom-bar {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  padding: 12px 20px;
  background: #fff;
  box-shadow: 0 -2px 8px rgba(0, 0, 0, 0.1);
  z-index: 99;

  .buy-btn {
    width: 100%;
    height: 40px;
    font-size: 16px;
  }
}

// 购票抽屉样式
:deep(.ticket-drawer) {
  border-radius: 16px 16px 0 0;

  .drawer-content {
    padding: 20px;

    .drawer-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 20px;

      h3 {
        margin: 0;
        font-size: 18px;
        font-weight: 500;
      }

      .close-btn {
        font-size: 20px;
        cursor: pointer;
        color: #909399;

        &:hover {
          color: #333;
        }
      }
    }

    .ticket-info {
      background: #f8f8f8;
      border-radius: 8px;
      padding: 16px;
      margin-bottom: 20px;

      .price-info, .stock-info {
        display: flex;
        justify-content: space-between;
        align-items: center;

        &:not(:last-child) {
          margin-bottom: 8px;
        }

        .label {
          color: #666;
        }

        .price {
          color: #f56c6c;
          font-size: 20px;
          font-weight: bold;
        }

        .stock {
          color: #333;
        }
      }
    }

    .ticket-form {
      margin-bottom: 20px;
    }

    .total-section {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 16px 0;
      border-top: 1px solid #eee;
      margin-bottom: 20px;

      .label {
        font-size: 16px;
        color: #333;
      }

      .total-price {
        color: #f56c6c;
        font-size: 24px;
        font-weight: bold;
      }
    }

    .drawer-footer {
      .submit-btn {
        width: 100%;
        height: 44px;
        font-size: 16px;
      }
    }
  }
}

.payment-section {
  margin-bottom: 20px;

  .section-title {
    font-size: 16px;
    color: #333;
    margin-bottom: 12px;
  }

  .payment-methods {
    display: flex;
    gap: 12px;

    .payment-method {
      flex: 1;
      display: flex;
      align-items: center;
      gap: 8px;
      padding: 12px;
      border: 1px solid #dcdfe6;
      border-radius: 8px;
      cursor: pointer;
      transition: all 0.3s;

      img {
        width: 24px;
        height: 24px;
        object-fit: contain;
      }

      &.active {
        border-color: var(--el-color-primary);
        background: var(--el-color-primary-light-9);
      }
    }
  }
}

.qrcode-dialog {
  .qrcode-content {
    .qrcode {
      width: 200px;
      height: 200px;
      display: block;
      margin: 0 auto;
    }
  }
}

.map-card {
  margin-top: 20px;

  .card-header {
    display: flex;
    justify-content: space-between;
    align-items: center;

    h3 {
      margin: 0;
      font-size: 18px;
      color: #303133;
    }
  }

  .map-container {
    height: 400px;
    margin: 10px 0;
    border-radius: 4px;
    overflow: hidden;
  }
}

.navigation-content {
  .navigation-map {
    height: 400px;
    margin-bottom: 20px;
  }

  .route-panel {
    max-height: 400px;
    overflow-y: auto;
    padding: 10px;
    background: #fff;
    border: 1px solid #ddd;
    border-radius: 4px;
  }

  .nav-options {
    margin-bottom: 20px;
    display: flex;
    justify-content: center;
  }

  .route-info {
    margin-top: 20px;
    padding: 15px;
    background: #f5f7fa;
    border-radius: 4px;

    .info-item {
      display: flex;
      margin-bottom: 10px;

      .label {
        width: 100px;
        color: #606266;
      }

      .value {
        color: #303133;
        font-weight: 500;
      }
    }
  }
}

/* 响应式适配 */
@media screen and (max-width: 768px) {
  .map-container {
    height: 300px;
  }
  
  .navigation-map {
    height: 350px;
  }
  
  .nav-options {
    flex-wrap: wrap;
  }
}
</style> 
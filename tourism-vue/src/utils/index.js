/**
 * 格式化时间
 * @param {string} time 时间字符串
 * @returns {string} 格式化后的时间
 */
export const formatTime = (time) => {
  if (!time) return ''
  const date = new Date(time)
  const year = date.getFullYear()
  const month = String(date.getMonth() + 1).padStart(2, '0')
  const day = String(date.getDate()).padStart(2, '0')
  const hour = String(date.getHours()).padStart(2, '0')
  const minute = String(date.getMinutes()).padStart(2, '0')
  return `${year}-${month}-${day} ${hour}:${minute}`
}

/**
 * 获取媒体文件URL
 * @param {string} url 文件路径
 * @returns {string} 完整URL
 */
export const getMediaUrl = (url) => {
  if (!url) return ''
  if (url.startsWith('http')) return url
  return `${import.meta.env.VITE_API_URL}${url}`
}

/**
 * 文件上传前检查
 * @param {File} file 文件对象
 * @returns {boolean} 是否通过检查
 */
export const beforeUpload = (file) => {
  // 检查文件类型
  const isImage = file.type.startsWith('image/')
  if (!isImage) {
    ElMessage.error('只能上传图片文件!')
    return false
  }
  
  // 检查文件大小
  const isLt2M = file.size / 1024 / 1024 < 2
  if (!isLt2M) {
    ElMessage.error('图片大小不能超过 2MB!')
    return false
  }
  
  return true
}

/**
 * 处理上传成功
 * @param {Object} res 上传响应
 * @param {Object} form 表单对象
 */
export const handleUploadSuccess = (res, form) => {
  if (res.code === 200) {
    form.coverUrl = res.data
    ElMessage.success('上传成功')
  } else {
    ElMessage.error('上传失败')
  }
}

/**
 * 分类选项
 */
export const categories = [
  { label: '景点玩法', value: 'spot' },
  { label: '美食推荐', value: 'food' },
  { label: '住宿建议', value: 'hotel' },
  { label: '交通指南', value: 'traffic' }
] 
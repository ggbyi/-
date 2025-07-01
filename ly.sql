/*
 Navicat Premium Data Transfer

 Source Server         : 本机
 Source Server Type    : MySQL
 Source Server Version : 50724
 Source Host           : localhost:3306
 Source Schema         : ly

 Target Server Type    : MySQL
 Target Server Version : 50724
 File Encoding         : 65001

 Date: 02/06/2025 15:16:29
*/

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for role
-- ----------------------------
DROP TABLE IF EXISTS `role`;
CREATE TABLE `role`  (
  `role_id` int(11) NOT NULL AUTO_INCREMENT COMMENT '角色ID',
  `role_name` varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '角色名称',
  `role_desc` varchar(100) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '角色描述',
  `status` tinyint(4) NULL DEFAULT 1 COMMENT '状态 1:正常 0:禁用',
  `created_time` datetime NULL DEFAULT NULL COMMENT '创建时间',
  `updated_time` datetime NULL DEFAULT NULL COMMENT '更新时间',
  PRIMARY KEY (`role_id`) USING BTREE,
  UNIQUE INDEX `role_name`(`role_name`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 4 CHARACTER SET = utf8 COLLATE = utf8_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of role
-- ----------------------------
INSERT INTO `role` VALUES (1, 'ROLE_ADMIN', '系统管理员，拥有所有权限', 1, '2025-02-08 16:41:34', NULL);
INSERT INTO `role` VALUES (2, 'ROLE_USER', '普通用户，基础功能权限', 1, '2025-02-08 16:41:34', NULL);
INSERT INTO `role` VALUES (3, 'ROLE_VIP', 'VIP用户，享有特殊权限', 1, '2025-02-08 16:41:34', NULL);

-- ----------------------------
-- Table structure for spot_favorite
-- ----------------------------
DROP TABLE IF EXISTS `spot_favorite`;
CREATE TABLE `spot_favorite`  (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT 'ID',
  `user_id` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '用户ID',
  `spot_id` int(11) NOT NULL COMMENT '景点ID',
  `created_time` datetime NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `uk_user_spot`(`user_id`, `spot_id`) USING BTREE,
  INDEX `fk_spot_favorite_spot`(`spot_id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 9 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '景点收藏表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of spot_favorite
-- ----------------------------
INSERT INTO `spot_favorite` VALUES (8, '8', 7, '2025-02-15 22:44:37');

-- ----------------------------
-- Table structure for spot_like
-- ----------------------------
DROP TABLE IF EXISTS `spot_like`;
CREATE TABLE `spot_like`  (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT 'ID',
  `user_id` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '用户ID',
  `spot_id` int(11) NOT NULL COMMENT '景点ID',
  `created_time` datetime NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `uk_user_spot`(`user_id`, `spot_id`) USING BTREE,
  INDEX `fk_spot_like_spot`(`spot_id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 16 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '景点点赞表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of spot_like
-- ----------------------------
INSERT INTO `spot_like` VALUES (5, '7', 2, '2025-02-11 00:16:55');
INSERT INTO `spot_like` VALUES (7, '7', 9, '2025-02-13 18:28:41');
INSERT INTO `spot_like` VALUES (13, '8', 4, '2025-02-15 16:09:47');
INSERT INTO `spot_like` VALUES (14, '8', 1, '2025-02-15 16:48:20');
INSERT INTO `spot_like` VALUES (15, '8', 7, '2025-02-15 22:44:36');

-- ----------------------------
-- Table structure for spot_view
-- ----------------------------
DROP TABLE IF EXISTS `spot_view`;
CREATE TABLE `spot_view`  (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '记录 ID',
  `user_id` varchar(32) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '用户 ID',
  `spot_id` int(11) NOT NULL COMMENT '景点 ID',
  `view_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '浏览时间',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_user_id`(`user_id`) USING BTREE,
  INDEX `idx_spot_id`(`spot_id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8 COLLATE = utf8_general_ci COMMENT = '用户景点浏览记录表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of spot_view
-- ----------------------------

-- ----------------------------
-- Table structure for t_guide
-- ----------------------------
DROP TABLE IF EXISTS `t_guide`;
CREATE TABLE `t_guide`  (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '攻略ID',
  `title` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '标题',
  `cover_url` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '封面图片',
  `content` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '攻略内容',
  `spot_id` int(11) NULL DEFAULT NULL COMMENT '关联景点ID',
  `category` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '分类(景点玩法/美食/住宿/交通)',
  `views` int(11) NULL DEFAULT 0 COMMENT '浏览量',
  `like_count` int(11) NULL DEFAULT 0 COMMENT '点赞数',
  `comment_count` int(11) NULL DEFAULT 0 COMMENT '评论数',
  `status` tinyint(4) NULL DEFAULT 1 COMMENT '状态(0:待审核,1:已发布,2:已拒绝)',
  `creator_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '创建者ID',
  `created_time` datetime NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_time` datetime NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 9 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '旅游攻略表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of t_guide
-- ----------------------------
INSERT INTO `t_guide` VALUES (1, '北京旅游攻略', '', '北京是中国的首都，有着丰富的历史和文化...', 1, '景点玩法', 1006, 50, 10, 1, '7', '2025-02-11 14:10:00', '2025-02-25 21:02:59');
INSERT INTO `t_guide` VALUES (2, '上海美食攻略', '', '上海有着丰富的美食选择，著名的小笼包...1', 2, '美食', 1500, 100, 20, 1, '8', '2025-02-11 14:10:00', '2025-02-24 21:31:43');
INSERT INTO `t_guide` VALUES (3, '成都住宿推荐', '', '成都有着许多高性价比的酒店，适合家庭入住...', 3, '住宿', 802, 40, 5, 1, '6', '2025-02-11 14:10:00', '2025-02-24 23:51:54');
INSERT INTO `t_guide` VALUES (4, '成都交通攻略', '', '成都的公共交通非常便捷，有着多个地铁线路...', 3, '交通', 600, 30, 3, 1, '7', '2025-02-11 14:10:00', '2025-02-24 21:31:45');
INSERT INTO `t_guide` VALUES (5, '1111', '', '1111', 7, 'food', 15, 0, 0, 1, '7', '2025-02-13 16:41:54', '2025-02-25 23:18:05');
INSERT INTO `t_guide` VALUES (6, '1111', '', '1111', NULL, 'traffic', 3, 0, 0, 1, '8', '2025-02-14 22:17:09', '2025-02-24 21:31:50');
INSERT INTO `t_guide` VALUES (7, '24', '/static/uploads/images/40082812-9cc7-430c-a60c-190427746bde.jpg', '557', NULL, 'spot', 5, 0, 1, 1, '8', '2025-02-14 22:42:06', '2025-02-24 21:32:28');
INSERT INTO `t_guide` VALUES (8, 'rtry', '/static/uploads/images/993b9edd-b64b-4382-8c11-e5325675e6f2.jpg', 'iiu', NULL, 'hotel', 22, 0, 5, 2, '8', '2025-02-14 22:42:25', '2025-02-26 23:33:22');

-- ----------------------------
-- Table structure for t_guide_comment
-- ----------------------------
DROP TABLE IF EXISTS `t_guide_comment`;
CREATE TABLE `t_guide_comment`  (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '评论ID',
  `guide_id` int(11) NOT NULL COMMENT '攻略ID',
  `user_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '用户ID',
  `content` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '评论内容',
  `created_time` datetime NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '攻略评论表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of t_guide_comment
-- ----------------------------

-- ----------------------------
-- Table structure for t_guide_like
-- ----------------------------
DROP TABLE IF EXISTS `t_guide_like`;
CREATE TABLE `t_guide_like`  (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT 'ID',
  `guide_id` int(11) NOT NULL COMMENT '攻略ID',
  `user_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '用户ID',
  `created_time` datetime NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 32 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '攻略点赞表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of t_guide_like
-- ----------------------------
INSERT INTO `t_guide_like` VALUES (15, 2, '7', '2025-02-11 14:12:27');
INSERT INTO `t_guide_like` VALUES (17, 4, '8', '2025-02-11 14:12:27');
INSERT INTO `t_guide_like` VALUES (18, 5, '8', '2025-02-11 14:12:27');
INSERT INTO `t_guide_like` VALUES (23, 1, '7', '2025-02-14 00:15:27');
INSERT INTO `t_guide_like` VALUES (31, 3, '8', '2025-02-24 23:51:54');

-- ----------------------------
-- Table structure for t_order
-- ----------------------------
DROP TABLE IF EXISTS `t_order`;
CREATE TABLE `t_order`  (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `order_no` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '订单号',
  `user_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '用户ID',
  `spot_id` int(11) NOT NULL COMMENT '景点ID',
  `spot_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '景点名称',
  `quantity` int(11) NOT NULL COMMENT '购票数量',
  `unit_price` decimal(10, 2) NOT NULL COMMENT '单价',
  `total_price` decimal(10, 2) NOT NULL COMMENT '总价',
  `visit_date` date NOT NULL COMMENT '游玩日期',
  `status` tinyint(4) NOT NULL COMMENT '状态(0:待支付,1:已支付,2:已取消)',
  `need_insurance` tinyint(1) NOT NULL DEFAULT 0 COMMENT '是否需要保险',
  `created_time` datetime NULL DEFAULT NULL COMMENT '创建时间',
  `pay_time` datetime NULL DEFAULT NULL COMMENT '支付时间',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `uk_order_no`(`order_no`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '订单表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of t_order
-- ----------------------------

-- ----------------------------
-- Table structure for t_refund
-- ----------------------------
DROP TABLE IF EXISTS `t_refund`;
CREATE TABLE `t_refund`  (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '退款ID',
  `order_id` int(11) NOT NULL COMMENT '订单ID',
  `user_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '用户ID',
  `reason` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '退款原因',
  `description` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '详细说明',
  `amount` decimal(10, 2) NOT NULL COMMENT '退款金额',
  `status` tinyint(4) NOT NULL COMMENT '状态(0:待处理,1:已退款,2:已拒绝)',
  `created_time` datetime NULL DEFAULT NULL COMMENT '申请时间',
  `process_time` datetime NULL DEFAULT NULL COMMENT '处理时间',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_order_id`(`order_id`) USING BTREE,
  INDEX `idx_user_id`(`user_id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 4 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '退款表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of t_refund
-- ----------------------------
INSERT INTO `t_refund` VALUES (1, 6, '8', '天气原因', '111', 210.00, 0, '2025-02-15 14:01:55', NULL);
INSERT INTO `t_refund` VALUES (2, 4, '8', '行程变更', '11', 80.00, 0, '2025-02-25 22:10:01', NULL);
INSERT INTO `t_refund` VALUES (3, 10, '17405792547402569', '天气原因', '22', 241.00, 0, '2025-02-26 23:10:49', NULL);

-- ----------------------------
-- Table structure for t_spot
-- ----------------------------
DROP TABLE IF EXISTS `t_spot`;
CREATE TABLE `t_spot`  (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '景点ID',
  `name` varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '景点名称',
  `category_id` int(11) NOT NULL COMMENT '所属分类ID',
  `cover_url` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '',
  `price` decimal(10, 2) NOT NULL DEFAULT 0.00 COMMENT '门票价格',
  `open_time` time NOT NULL COMMENT '开放时间',
  `close_time` time NOT NULL COMMENT '关闭时间',
  `description` text CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '景点介绍',
  `location` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '地理位置',
  `status` tinyint(4) NOT NULL DEFAULT 1 COMMENT '状态:0-禁用,1-启用',
  `create_time` datetime NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime NULL DEFAULT CURRENT_TIMESTAMP,
  `address` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '景点地址',
  `images` text CHARACTER SET utf8 COLLATE utf8_general_ci NULL COMMENT '景点图片列表',
  `video_url` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '景点视频地址',
  `rating` decimal(3, 1) NOT NULL DEFAULT 0.0 COMMENT '评分',
  `views` int(11) NOT NULL DEFAULT 0 COMMENT '浏览次数',
  `features` text CHARACTER SET utf8 COLLATE utf8_general_ci NULL COMMENT '景点特色',
  `history` text CHARACTER SET utf8 COLLATE utf8_general_ci NULL COMMENT '历史背景',
  `latitude` varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '纬度',
  `longitude` varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '经度',
  `traffic` text CHARACTER SET utf8 COLLATE utf8_general_ci NULL COMMENT '交通指南',
  `notice` text CHARACTER SET utf8 COLLATE utf8_general_ci NULL COMMENT '注意事项',
  `like_count` int(11) NULL DEFAULT 0,
  `favorite_count` int(11) NULL DEFAULT 0,
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `category_id`(`category_id`) USING BTREE,
  CONSTRAINT `t_spot_ibfk_1` FOREIGN KEY (`category_id`) REFERENCES `t_spot_category` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 5 CHARACTER SET = utf8 COLLATE = utf8_general_ci COMMENT = '景点表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of t_spot
-- ----------------------------
INSERT INTO `t_spot` VALUES (3, '迪士尼乐园', 3, '/static/uploads//images/4171b254-f39e-47af-996e-8667c9b16217.jpg', 499.00, '09:00:00', '21:00:00', '上海迪士尼乐园是中国大陆首座迪士尼主题乐园，园区内设有七大主题园区，包括米奇大街、奇想花园、探险岛、宝藏湾、明日世界、梦幻世界和迪士尼小镇。', '上海市浦东新区川沙新镇黄赵路310号', 1, '2025-02-09 02:15:20', NULL, '', '/static/uploads//images/4171b254-f39e-47af-996e-8667c9b16217.jpg', NULL, 0.0, 0, NULL, NULL, NULL, NULL, NULL, NULL, 3, 3);
INSERT INTO `t_spot` VALUES (4, '国家博物馆', 4, '/static/uploads//images/031d9e41-80e9-43c9-942c-515685e005ee.jpg', 0.00, '09:00:00', '16:30:00', '中国国家博物馆是一座综合性博物馆，位于北京市中心天安门广场东侧。馆内收藏了大量珍贵的历史文物和艺术品。', '北京市东城区东长安街16号', 1, '2025-02-09 02:15:20', NULL, '', '/static/uploads//images/031d9e41-80e9-43c9-942c-515685e005ee.jpg', NULL, 0.0, 1, NULL, NULL, NULL, NULL, NULL, NULL, 4, 3);

-- ----------------------------
-- Table structure for t_spot_category
-- ----------------------------
DROP TABLE IF EXISTS `t_spot_category`;
CREATE TABLE `t_spot_category`  (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '分类ID',
  `name` varchar(20) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '分类名称',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 8 CHARACTER SET = utf8 COLLATE = utf8_general_ci COMMENT = '景点分类表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of t_spot_category
-- ----------------------------
INSERT INTO `t_spot_category` VALUES (1, '自然风光', '2025-02-09 02:15:20', '2025-02-09 02:15:20');
INSERT INTO `t_spot_category` VALUES (2, '历史古迹', '2025-02-09 02:15:20', '2025-02-09 02:15:20');
INSERT INTO `t_spot_category` VALUES (3, '主题乐园', '2025-02-09 02:15:20', '2025-02-09 02:15:20');
INSERT INTO `t_spot_category` VALUES (4, '博物馆', '2025-02-09 02:15:20', '2025-02-09 02:15:20');
INSERT INTO `t_spot_category` VALUES (5, '公园游览', '2025-02-09 02:15:20', '2025-02-11 20:46:11');
INSERT INTO `t_spot_category` VALUES (7, '1111', '2025-02-23 22:35:25', '2025-02-23 22:35:25');

-- ----------------------------
-- Table structure for t_ticket_type
-- ----------------------------
DROP TABLE IF EXISTS `t_ticket_type`;
CREATE TABLE `t_ticket_type`  (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '票型ID',
  `spot_id` int(11) NOT NULL COMMENT '景点ID',
  `name` varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '票型名称',
  `price` decimal(10, 2) NOT NULL COMMENT '票价',
  `description` varchar(200) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '说明',
  `status` tinyint(4) NULL DEFAULT 1 COMMENT '状态:0-禁用,1-启用',
  `create_time` datetime NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `spot_id`(`spot_id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 6 CHARACTER SET = utf8 COLLATE = utf8_general_ci COMMENT = '门票类型表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of t_ticket_type
-- ----------------------------
INSERT INTO `t_ticket_type` VALUES (1, 1, '成人票', 100.00, '18岁以上成人使用', 1, '2025-02-09 14:11:59', '2025-02-09 14:11:59');
INSERT INTO `t_ticket_type` VALUES (2, 1, '儿童票', 50.00, '1.2米以下儿童使用', 1, '2025-02-09 14:11:59', '2025-02-09 14:11:59');
INSERT INTO `t_ticket_type` VALUES (3, 1, '学生票', 80.00, '凭有效学生证使用', 1, '2025-02-09 14:11:59', '2025-02-09 14:11:59');
INSERT INTO `t_ticket_type` VALUES (4, 2, '全价票', 60.00, '普通游客使用', 1, '2025-02-09 14:11:59', '2025-02-09 14:11:59');
INSERT INTO `t_ticket_type` VALUES (5, 2, '优惠票', 30.00, '老年人、军人等特殊群体使用', 1, '2025-02-09 14:11:59', '2025-02-09 14:11:59');

-- ----------------------------
-- Table structure for user
-- ----------------------------
DROP TABLE IF EXISTS `user`;
CREATE TABLE `user`  (
  `user_id` varchar(32) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '用户ID',
  `username` varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '用户名',
  `password` varchar(100) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '密码',
  `email` varchar(100) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '邮箱',
  `phone` varchar(20) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '手机号',
  `avatar_url` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '头像URL',
  `bio` text CHARACTER SET utf8 COLLATE utf8_general_ci NULL COMMENT '个人简介',
  `status` tinyint(4) NULL DEFAULT 1 COMMENT '状态 1:正常 0:禁用',
  `created_time` datetime NULL DEFAULT NULL COMMENT '创建时间',
  `updated_time` datetime NULL DEFAULT NULL COMMENT '更新时间',
  `last_login_time` datetime NULL DEFAULT NULL COMMENT '最后登录时间',
  `nickname` varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '昵称',
  `avatar` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '头像',
  `gender` tinyint(4) NULL DEFAULT 0 COMMENT '性别(0:保密 1:男 2:女)',
  PRIMARY KEY (`user_id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8 COLLATE = utf8_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of user
-- ----------------------------
INSERT INTO `user` VALUES ('1', 'admin', 'e10adc3949ba59abbe56e057f20f883e', 'admin@example.com', '13800138000', NULL, '系统管理员', 1, '2025-02-08 16:41:34', '2025-02-27 18:03:34', '2025-06-02 15:10:43', '', NULL, 1);
INSERT INTO `user` VALUES ('17407456888857576', 'user', 'e10adc3949ba59abbe56e057f20f883e', '2750295010@qq.com', NULL, NULL, NULL, 1, '2025-02-28 20:28:09', '2025-02-28 20:28:09', '2025-06-02 15:15:33', 'admin', 'default.jpg', 0);

-- ----------------------------
-- Table structure for user_follow
-- ----------------------------
DROP TABLE IF EXISTS `user_follow`;
CREATE TABLE `user_follow`  (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '关注者ID',
  `follow_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '被关注者ID',
  `created_time` datetime NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `uk_user_follow`(`user_id`, `follow_id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '用户关注表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of user_follow
-- ----------------------------

-- ----------------------------
-- Table structure for user_like
-- ----------------------------
DROP TABLE IF EXISTS `user_like`;
CREATE TABLE `user_like`  (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` varchar(32) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '用户ID',
  `target_id` int(11) NOT NULL COMMENT '点赞目标ID',
  `target_type` varchar(20) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '点赞类型(spot/guide/post)',
  `created_time` datetime NOT NULL COMMENT '点赞时间',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `uk_user_like`(`user_id`, `target_id`, `target_type`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8 COLLATE = utf8_general_ci COMMENT = '用户点赞记录表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of user_like
-- ----------------------------

-- ----------------------------
-- Table structure for user_preference
-- ----------------------------
DROP TABLE IF EXISTS `user_preference`;
CREATE TABLE `user_preference`  (
  `user_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '用户ID',
  `spot_types` json NULL COMMENT '景点类型偏好',
  `price_range` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '价格区间',
  `travel_mode` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '出行方式',
  `updated_time` datetime NULL DEFAULT NULL COMMENT '更新时间',
  PRIMARY KEY (`user_id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '用户偏好设置' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of user_preference
-- ----------------------------

-- ----------------------------
-- Table structure for user_role
-- ----------------------------
DROP TABLE IF EXISTS `user_role`;
CREATE TABLE `user_role`  (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT 'ID',
  `user_id` varchar(20) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '用户ID',
  `role_id` int(11) NOT NULL COMMENT '角色ID',
  `created_time` datetime NULL DEFAULT NULL COMMENT '创建时间',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `user_id`(`user_id`) USING BTREE,
  INDEX `role_id`(`role_id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 12 CHARACTER SET = utf8 COLLATE = utf8_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of user_role
-- ----------------------------
INSERT INTO `user_role` VALUES (1, '1', 1, '2025-02-08 16:41:34');
INSERT INTO `user_role` VALUES (11, '17407456888857576', 2, '2025-02-28 20:28:09');

SET FOREIGN_KEY_CHECKS = 1;

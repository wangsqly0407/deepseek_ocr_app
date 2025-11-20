# DeepSeek OCR GPU内存问题修复说明

## 问题描述
Docker服务启动时出现CUDA out of memory错误，容器尝试使用所有GPU但内存不足。

## 解决方案

### 1. 修改Docker配置
- **文件**: `docker-compose.yml`
- **修改**: 指定仅使用GPU 4，避免与其他GPU冲突
- **添加**: GPU内存优化环境变量

### 2. 优化后端代码
- **文件**: `backend/main.py`
- **修改**: 添加智能GPU设备选择逻辑
- **效果**: 根据环境变量自动选择正确的GPU设备

### 3. 创建环境配置
- **文件**: `.env`
- **配置**: GPU分配和内存优化参数
- **优化**: 降低处理参数减少内存占用

## 使用方法

### 重启服务
```bash
# 使用优化的重启脚本
./scripts/restart_service.sh

# 或者手动重启
docker-compose down
./scripts/check_gpu_status.sh
docker-compose up -d
```

### 检查GPU状态
```bash
# 检查所有GPU状态
./scripts/check_gpu_status.sh

# 检查GPU 4特定状态
nvidia-smi -i 4
```

### 监控服务日志
```bash
# 查看后端日志
docker-compose logs -f backend

# 查看所有服务日志
docker-compose logs -f
```

## 配置参数说明

### GPU配置
- `CUDA_VISIBLE_DEVICES=4`: 指定使用GPU 4
- `NVIDIA_VISIBLE_DEVICES=4`: Docker GPU设备限制
- `PYTORCH_CUDA_ALLOC_CONF`: PyTorch内存分配优化

### 内存优化
- `BASE_SIZE=800`: 降低基础处理尺寸（原1024）
- `IMAGE_SIZE=512`: 降低图像处理尺寸（原640）
- `expandable_segments:True`: 启用可扩展内存段

## 故障排除

### 内存不足
1. 检查GPU 4是否被其他进程占用
2. 使用 `./scripts/check_gpu_status.sh` 查看内存使用
3. 考虑调整BASE_SIZE和IMAGE_SIZE参数

### 服务启动失败
1. 检查Docker日志: `docker-compose logs backend`
2. 确认GPU 4可用且有足够内存
3. 检查模型文件是否正确挂载

### 性能优化
1. 根据GPU内存调整处理参数
2. 监控GPU使用率和温度
3. 定期清理GPU内存碎片

## 访问地址
- **前端**: http://localhost:3000
- **后端API**: http://localhost:8000
- **API文档**: http://localhost:8000/docs
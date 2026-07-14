# SoulX-Singer Windows AMD ROCm Patch

这是 [Soul-AILab/SoulX-Singer](https://github.com/Soul-AILab/SoulX-Singer) 的非官方 Windows AMD ROCm 与 SVC 中间层接口补丁。本仓库只发布修改差异、AMD 依赖清单和启动脚本，不重新分发官方项目、模型权重、FFmpeg、Python/ROCm 运行时或生成音频。

补丁基于上游提交：`81aeb3a`（`update wechat QR code`）。

## 包含的修改

- 为 Windows AMD ROCm 单卡环境保护缺失的 `torch.distributed` API。
- 使用 SoundFile 读取 PCM WAV，绕开 AMD 自定义 PyTorch 与 TorchCodec/FFmpeg DLL 的兼容问题。
- 优先使用本地 `openai-whisper-base`，离线环境仍可启动。
- 为 SoulX-SVC 增加 Prompt/Target/F0 和逐分段推理进度回调。
- 暴露 `/soulx_svc_convert` 与本机路径接口 `/soulx_svc_convert_path`，供 SVCVC 中间层调用。
- 将 SoulX-SVC 的种子输入扩展到完整无符号 32 位范围 `0～4294967295`，与插件和中间层保持一致。
- 限制 SVC 会话输出保留数量，并保护正在运行及正在返回的结果。
- WebUI 仅绑定 `127.0.0.1`，启动脚本安全清理旧端口。
- 提供不覆盖 AMD PyTorch/ROCm 的依赖清单。

## 应用补丁

先克隆官方项目并切到本补丁对应的提交：

```powershell
git clone https://github.com/Soul-AILab/SoulX-Singer.git
cd SoulX-Singer
git checkout 81aeb3a
git apply "..\SoulX-Singer-AMD-Patch\patches\soulx-singer-amd-windows.patch"
Copy-Item "..\SoulX-Singer-AMD-Patch\overlay\*" . -Recurse -Force
```

之后需要自行准备：

1. 官方 SoulX-Singer 模型，目录结构遵循上游说明。
2. `runtime-rocm/` Windows AMD Python 环境；本地验证栈为 PyTorch `2.9.1+rocm7.2.1` / HIP 7.2.x。
3. `ffmpeg/bin/`，或把 FFmpeg 加入系统 `PATH`。
4. 在 AMD 环境中安装 `overlay/requirements-amd-rocm.txt`；该文件刻意不安装或替换 `torch`、`torchaudio`、`torchvision`。

完成后运行 `启动SoulX-Singer.bat`，选择 SVC（7861）或 SVS（7860）。

## 中间层

配套的 AstrBot/SoulX SVC 网关位于 [sdfsfsk/SVCVC-API-SVF](https://github.com/sdfsfsk/SVCVC-API-SVF)。中间层负责歌曲下载、参考音色管理、结果缓存、MP3 导出和向 AstrBot 转发进度；实际 GPU 推理由本补丁后的 SoulX-Singer 完成。

## 许可证与归属

SoulX-Singer 原始项目版权归 Soul-AILab 及其贡献者所有，使用 Apache License 2.0。本仓库是非官方兼容补丁，与 Soul-AILab 无隶属或背书关系。官方模型仍受其各自许可和使用条款约束。

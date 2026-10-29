# 素材来源登记

每个进入游戏的素材一行。发布时据此标注 AI 与工具的使用情况；招到美术合作者后，据此决定哪些素材优先替换。

| 文件 | 来源 | 处理工具 | 用户参与 | AI 参与 | 备注 |
|---|---|---|---|---|---|
| `assets/style_sample/s05_normal.png` | 用户自拍 `art/raw/museum2/IMG_1897.JPG`（墙、地面、天花） | `tools/art/s05_style_sample.py`（OpenCV/Pillow：透视校正、去除两件展出作品、冷调降光、颗粒） | 取景拍摄；冷暖方案 B；选用 S05 墙面 | Claude 编写处理脚本与参数 | 原图中的两件艺术作品已移除，不进入游戏 |
| 同上，画中《窗》 | 程序绘制（尖拱形状参考 `art/raw/窗/IMG_1871.JPG`，未复制其玻璃图案或纹章） | 同一脚本（Kuwahara 油画化、笔触纹理） | 选定“哥特尖拱在冷白深处发暖光”的方向 | Claude 程序生成，非图像生成模型 | 占位品质，可由用户在 iPad 重绘替换 |
| `assets/style_sample/s05_normal_handle.png`, `s05_normal_open.png` | 程序绘制 | 同上 | — | Claude 程序生成 | 把手、打开状态 |
| `assets/style_sample/s05_bluelake*.png` | 由 IMG_1897 边缘提取 + 程序绘制粉笔线 + 代码文字 | 同上（Canny 边缘、粉笔颗粒） | 蓝湖层“蓝屏 + 白色粉笔/代码”的方向来自用户的海报构想 | Claude 程序生成；墙上代码文本由 Claude 撰写，台词取自游戏现有对白 | 关键物件建议之后由用户手绘粉笔线 |

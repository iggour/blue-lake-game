import fs from "node:fs/promises";
import { SpreadsheetFile, Workbook } from "@oai/artifact-tool";

const outputDir = "/Users/zhangtongyang/Desktop/blue lake/.artifacts";
const outputPath = `${outputDir}/美术馆流程.xlsx`;
await fs.mkdir(outputDir, { recursive: true });

const wb = Workbook.create();
const sheet = wb.worksheets.add("美术馆流程");

sheet.getRange("A1:H1").merge();
sheet.getRange("A1").values = [["《蓝湖》美术馆 Slice 流程表"]];
sheet.getRange("A2:H2").merge();
sheet.getRange("A2").values = [["第一章：真理美术馆事件与玩家认知变化"]];

const headers = [[
  "Slice 剧情 / 事件",
  "核心谜题 / 事件机制",
  "主题",
  "玩家离开时认知",
  "地图状态",
  "美术方向（后做）",
  "音乐方向（后做）",
  "备注"
]];

const rows = [
  ["S01 进入", "Grehan 与蓝湖从旧照片进入美术馆；发现没有明显出口", "探索事件：通过环境、旧照片、保安/入口信息建立“寻找出口”目标", "进入 / 观看", "“我要出去。”", "美术馆初始状态；入口 → 展厅开放", "正常、略陈旧的美术馆；旧照片作为视觉锚点", "安静、空旷、略有不真实感；暂不制造恐怖"],
  ["S02 迷路", "Grehan 按正常路线探索，却不断回到原处；保安指向一条死路", "空间循环谜题：玩家发现自己不是单纯迷路，而是空间本身在循环", "空间 / 方向", "“这里不是普通的美术馆，空间有问题。”", "普通空间循环状态", "重复的构图、相似展厅，让玩家产生方向感错乱", "音乐出现轻微循环感；重复段落但不明显提示"],
  ["S03 镜子", "死路处的镜子显示现实中不存在的门/结构", "镜像空间谜题：普通视觉与镜中信息冲突；蓝湖观察后发现另一种空间，并利用它突破循环", "视觉 ≠ 现实", "“蓝湖看到的世界和我看到的不一样。”", "第一次发生真正的空间突破；开放新展区", "镜面、反射、轮廓异常；蓝湖视角下出现不同空间信息", "音乐第一次出现明显“另一层”的声音/音色"],
  ["S04 参观者", "遇到无法通过脸辨认人的参观者；找到修复师后，两人通过声音、动作、轮廓与色彩重新认出彼此", "认知事件 / 轻谜题：不是寻找“正确的人脸”，而是寻找能够被这个人识别的特征", "不同的视觉经验", "“看见不是唯一的，也不是绝对客观的。”", "新展区稳定开放；人物关系成为环境叙事的一部分", "人脸/肖像出现轻微视角差异；轮廓、色彩成为视觉元素", "两套互补主题逐渐合并；“轮廓/色彩”成为音乐概念"],
  ["S05 《窗》", "找到画中的窗；结合前面获得的信息，意识到它可能不是普通画作", "第一次 Blue Lake 世界干预：蓝湖使《窗》从“画”变成可作用的通路", "观看 → 改变", "“蓝湖不只是让我看见，它能改变东西。”", "《窗》第一次开启；但出口通向中央展台，而非外部", "画框与真实空间边界模糊；窗内外视觉连续", "音乐从美术馆主题过渡到中央展台主题"],
  ["S06 中央展台", "《看见》空展台；文字写着“看见即存在”；蓝湖介入后发现隐藏的 Kent 视觉传感器", "存在谜题：普通视角为空；蓝湖视角揭示原本不可见的物体", "看见 / 存在", "“不可见不等于不存在。”；“蓝湖可能连接这个世界的另一层。”", "中央展台事件完成；Kent 线正式与美术馆产生联系", "空展台极简化；蓝湖视角中出现隐藏结构/物件", "第一章最重要的音乐揭示；Blue Lake 主题与 Kent 主题第一次结合"],
  ["S07 回访", "中央展台事件后，美术馆重新开放；玩家可以重新阅读之前走过的区域", "二次探索谜题：蓝湖状态下发现之前无法看到的痕迹、物件、记录和细节", "重新观看 / 第二次阅读", "“同一个地方，在不同观察方式下是不同的世界。”", "全美术馆回访状态；旧区域获得第二层内容", "同一场景的 Blue Lake 层：痕迹、隐藏信息、细节变化", "第一章已有主题重新出现，但加入新的层次；不是单纯升级音乐"],
  ["S08 真正出口", "玩家再次来到《窗》；这次它通向真正的外部", "状态谜题 / 认知回收：玩家根据此前经验主动再次使用《窗》", "理解规则 / 离开", "“我已经理解了这里的规则。”", "《窗》→ 外部；第一章结束，进入下一章", "窗户真正打开；美术馆与外部世界产生强烈空间反差", "第一章主题收束；Blue Lake 主题留下延续到下一章的尾音"]
];

sheet.getRange("A4:H4").values = headers;
sheet.getRange("A5:H12").values = rows;

sheet.getRange("A1:H12").format.font = { name: "Arial", size: 10, color: "#1F2937" };
sheet.getRange("A1:H1").format = {
  fill: "#17324D",
  font: { name: "Arial", size: 16, bold: true, color: "#FFFFFF" },
  horizontalAlignment: "center",
  verticalAlignment: "center",
};
sheet.getRange("A2:H2").format = {
  fill: "#DCEAF3",
  font: { name: "Arial", size: 11, italic: true, color: "#17324D" },
  horizontalAlignment: "center",
  verticalAlignment: "center",
};
sheet.getRange("A4:H4").format = {
  fill: "#2E6F95",
  font: { name: "Arial", size: 10, bold: true, color: "#FFFFFF" },
  horizontalAlignment: "center",
  verticalAlignment: "center",
  wrapText: true,
};
sheet.getRange("A5:H12").format = {
  verticalAlignment: "top",
  wrapText: true,
};
sheet.getRange("A5:A12").format = { font: { bold: true, color: "#17324D" } };
sheet.getRange("C5:C12").format = { fill: "#F4F8FB" };
sheet.getRange("D5:D12").format = { fill: "#FFF9E8" };

const widths = [15, 31, 40, 18, 29, 31, 31, 31];
for (let i = 0; i < widths.length; i++) {
  sheet.getRangeByIndexes(0, i, 1, 1).format.columnWidth = widths[i];
}
sheet.getRange("A1:H1").format.rowHeight = 30;
sheet.getRange("A2:H2").format.rowHeight = 22;
sheet.getRange("A4:H4").format.rowHeight = 36;
sheet.getRange("A5:H12").format.rowHeight = 92;
sheet.freezePanes.freezeRows(4);

// Use an Excel table so the workflow remains filterable and extendable.
sheet.tables.add("A4:H12", true, "GallerySliceWorkflow");

wb.recalculate();
const check = await wb.inspect({ kind: "region", sheetId: "美术馆流程", range: "A1:H12", maxChars: 3000 });
console.log(check.ndjson ?? check);
const preview = await wb.render({ sheetName: "美术馆流程", autoCrop: "all", scale: 1, format: "png" });
await fs.writeFile(`${outputDir}/美术馆流程.png`, new Uint8Array(await preview.arrayBuffer()));
const file = await SpreadsheetFile.exportXlsx(wb);
await file.save(outputPath);
console.log(`saved ${outputPath}`);

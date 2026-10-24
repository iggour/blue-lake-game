import fs from "node:fs/promises";
import { FileBlob, SpreadsheetFile } from "@oai/artifact-tool";

const sourcePath = "/Users/zhangtongyang/Desktop/blue lake/workflow/美术馆/美术馆流程.xlsx";
const outputDir = "/Users/zhangtongyang/Desktop/blue lake/.artifacts";
const outputPath = `${outputDir}/美术馆流程_updated.xlsx`;
await fs.mkdir(outputDir, { recursive: true });

const input = await FileBlob.load(sourcePath);
const wb = await SpreadsheetFile.importXlsx(input);
const sheet = wb.worksheets.add("S01-S02实施");

sheet.getRange("A1:G1").merge();
sheet.getRange("A1").values = [["第一章美术馆 S01–S02 实施重点"]];
sheet.getRange("A2:G2").merge();
sheet.getRange("A2").values = [["只记录当前已实现的 Slice 目标、关键观察点和状态接口；不包含 S03 镜子谜题。"]];

sheet.getRange("A4:G4").values = [[
  "Slice",
  "主题",
  "核心事件",
  "玩家离开时认知",
  "当前游戏实现",
  "Blue Lake / 对话重点",
  "状态接口"
]];

sheet.getRange("A5:G6").values = [
  [
    "S01 进入",
    "进入 / 观看",
    "通过旧照片进入真理美术馆；观察入口、第一件展品和出口区域",
    "我要出去。",
    "三项 E 观察全部完成后，记录没有明显出口；不启用 Blue Lake、镜子或《窗》谜题",
    "“这里没有一个正常的出口。我要继续往里面走。”随后：“往里面走吧。也许出口还在更深处。”",
    "map_state = Museum_S01_Initial；s01 completed；goal = find_a_way_out；解锁 S02"
  ],
  [
    "S02 迷路",
    "空间 / 方向",
    "保安指向通道；玩家抵达死路；走入通道后返回入口；重复两次后确认不是普通迷路",
    "这里的空间有问题。",
    "保安和死路使用 E 观察；通道触发空间回返；第二次回返后完成 S02。暂不实现镜子突破",
    "“……我们又回来了。”、“不是你走错了。”、“这里在重复。”",
    "map_state = Museum_S02_Loop；s02 completed；goal = understand_the_space；解锁 S03"
  ]
];

sheet.getRange("A1:G6").format.font = { name: "Arial", size: 10, color: "#1F2937" };
sheet.getRange("A1:G1").format = {
  fill: "#17324D",
  font: { name: "Arial", size: 16, bold: true, color: "#FFFFFF" },
  horizontalAlignment: "center",
  verticalAlignment: "center",
};
sheet.getRange("A2:G2").format = {
  fill: "#DCEAF3",
  font: { name: "Arial", size: 10, italic: true, color: "#17324D" },
  wrapText: true,
  horizontalAlignment: "center",
  verticalAlignment: "center",
};
sheet.getRange("A4:G4").format = {
  fill: "#2E6F95",
  font: { name: "Arial", size: 10, bold: true, color: "#FFFFFF" },
  wrapText: true,
  horizontalAlignment: "center",
  verticalAlignment: "center",
};
sheet.getRange("A5:G6").format = { wrapText: true, verticalAlignment: "top" };
sheet.getRange("A5:A6").format = { font: { bold: true, color: "#17324D" } };
sheet.getRange("C5:C6").format = { fill: "#F4F8FB" };
sheet.getRange("D5:D6").format = { fill: "#FFF9E8" };

const widths = [14, 18, 38, 24, 42, 42, 42];
for (let i = 0; i < widths.length; i++) {
  sheet.getRangeByIndexes(0, i, 1, 1).format.columnWidth = widths[i];
}
sheet.getRange("A1:G1").format.rowHeight = 30;
sheet.getRange("A2:G2").format.rowHeight = 28;
sheet.getRange("A4:G4").format.rowHeight = 36;
sheet.getRange("A5:G6").format.rowHeight = 118;
sheet.freezePanes.freezeRows(4);
sheet.tables.add("A4:G6", true, "GalleryS01S02Implementation");

const dialogueSheet = wb.worksheets.add("Slice对话提示");
dialogueSheet.getRange("A1:E1").merge();
dialogueSheet.getRange("A1").values = [["第一章 Slice 对话与提示表"]];
dialogueSheet.getRange("A2:E2").merge();
dialogueSheet.getRange("A2").values = [["用于记录事件、提示与 Slice 间认知转场，不替代具体对白脚本。"]];
dialogueSheet.getRange("A4:E4").values = [["Slice", "类型", "触发时机", "作用", "大致内容"]];
dialogueSheet.getRange("A5:E23").values = [
  ["S01", "Event", "玩家第一次发现“出口似乎不存在”", "确认异常，但不剧透", "这里好像没有出口。"],
  ["S01", "Hint", "玩家长时间漫无目的探索", "轻轻把目标拉回来", "暗示继续往展厅走"],
  ["S01→S02", "Transition", "玩家确认初始区域没有正常出口", "标记认知转变", "也许问题不在出口。"],
  ["S02", "Event", "玩家第一次回到已经经过的位置", "让玩家注意循环", "我们是不是来过这里？"],
  ["S02", "Hint", "玩家重复经过循环点数次", "帮助玩家确认不是自己记错", "……这已经不是第一次了。"],
  ["S02→S03", "Transition", "玩家确认空间循环", "把问题从“迷路”转成“世界异常”", "这里不是在带我们出去，它在把我们送回来。"],
  ["S03", "Event", "玩家发现镜子中的异常结构", "第一次正式引出 Blue Lake 的不同观察", "镜子里……有东西。"],
  ["S03", "Hint", "玩家已经发现镜中信息但无法行动", "轻提示，不直接给答案", "暗示“镜子里的东西可能有用”"],
  ["S03→S04", "Transition", "玩家成功突破镜子空间", "强化核心规则", "你刚才相信了一个眼睛看不到的东西。"],
  ["S04", "Event", "参观者再次认错 Grehan / 其他人", "强化视觉差异主题", "她看到的你，和你看到的自己不一样。"],
  ["S04→S05", "Transition", "参观者与修复师重逢", "从“视觉差异”转向“视觉可以被重新理解”", "原来认出一个人，不一定要看见他的脸。"],
  ["S05", "Event", "玩家发现《窗》可以被 Blue Lake 影响", "第一次确认 Blue Lake 能改变世界", "你把一幅画……打开了。"],
  ["S05→S06", "Transition", "《窗》通向中央展台", "制造疑问，不解释答案", "这不是出口。 / 那它为什么带我们来这里？"],
  ["S06", "Event", "蓝湖视角发现视觉传感器", "世界观揭示", "这里刚才明明什么都没有。"],
  ["S06→S07", "Transition", "玩家完成中央展台事件", "引导二次阅读", "我们是不是漏掉了什么？"],
  ["S07", "Ambient/Event", "玩家重新进入旧区域并发现隐藏内容", "让回访有意义", "少量、针对具体发现的评论"],
  ["S07→S08", "Transition", "玩家完成主要回访/获得离开条件", "让玩家主动想到《窗》", "我们是不是该再去看看那扇窗？"],
  ["S08", "Event", "玩家再次打开《窗》", "确认状态变化", "这次不一样。"],
  ["S08", "Transition", "真正离开美术馆", "第一章收束", "看来我们终于看见出口了。"],
];
dialogueSheet.getRange("A1:E23").format.font = { name: "Arial", size: 10, color: "#1F2937" };
dialogueSheet.getRange("A1:E1").format = {
  fill: "#17324D",
  font: { name: "Arial", size: 16, bold: true, color: "#FFFFFF" },
  horizontalAlignment: "center",
  verticalAlignment: "center",
};
dialogueSheet.getRange("A2:E2").format = {
  fill: "#DCEAF3",
  font: { name: "Arial", size: 10, italic: true, color: "#17324D" },
  wrapText: true,
  horizontalAlignment: "center",
  verticalAlignment: "center",
};
dialogueSheet.getRange("A4:E4").format = {
  fill: "#2E6F95",
  font: { name: "Arial", size: 10, bold: true, color: "#FFFFFF" },
  wrapText: true,
  horizontalAlignment: "center",
  verticalAlignment: "center",
};
dialogueSheet.getRange("A5:E23").format = { wrapText: true, verticalAlignment: "top" };
dialogueSheet.getRange("A5:A23").format = { font: { bold: true, color: "#17324D" } };
dialogueSheet.getRange("B5:B23").format = { fill: "#F4F8FB" };
dialogueSheet.getRange("D5:D23").format = { fill: "#FFF9E8" };
const dialogueWidths = [14, 18, 36, 32, 48];
for (let i = 0; i < dialogueWidths.length; i++) {
  dialogueSheet.getRangeByIndexes(0, i, 1, 1).format.columnWidth = dialogueWidths[i];
}
dialogueSheet.getRange("A1:E1").format.rowHeight = 30;
dialogueSheet.getRange("A2:E2").format.rowHeight = 28;
dialogueSheet.getRange("A4:E4").format.rowHeight = 36;
dialogueSheet.getRange("A5:E23").format.rowHeight = 62;
dialogueSheet.freezePanes.freezeRows(4);
dialogueSheet.tables.add("A4:E23", true, "GallerySliceDialogueGuidance");

wb.recalculate();
const inspect = await wb.inspect({ kind: "region", sheetId: "S01-S02实施", range: "A1:G6", maxChars: 3000 });
console.log(inspect.ndjson ?? inspect);
const preview = await wb.render({ sheetName: "S01-S02实施", autoCrop: "all", scale: 1, format: "png" });
await fs.writeFile(`${outputDir}/美术馆流程_updated.png`, new Uint8Array(await preview.arrayBuffer()));
const dialoguePreview = await wb.render({ sheetName: "Slice对话提示", autoCrop: "all", scale: 1, format: "png" });
await fs.writeFile(`${outputDir}/美术馆流程_dialogue.png`, new Uint8Array(await dialoguePreview.arrayBuffer()));
const output = await SpreadsheetFile.exportXlsx(wb);
await output.save(outputPath);
console.log(`saved ${outputPath}`);

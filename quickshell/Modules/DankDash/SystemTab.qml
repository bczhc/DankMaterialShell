import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Widgets

Item {
    id: root

    LayoutMirroring.enabled: I18n.isRtl
    LayoutMirroring.childrenInherit: true

    implicitWidth: 700
    implicitHeight: 410

    property Item focusTarget: null
    property Item tabBarItem: null
    property Item keyForwardTarget: null
    property var parentPopout: null

    // CPU Freq 状态
    property string currentCpuFreq: ""
    property bool overlayEnabled: false
    property bool isCheckingOverlay: false
    property bool isSettingOverlay: false

    // GPU Clock 频率数据
    property var gpuMemFreqs: []
    property var gpuGfxFreqs: []
    property string gpuMemMin: ""
    property string gpuMemMax: ""
    property string gpuGfxMin: ""
    property string gpuGfxMax: ""
    property string gpuMemRangeText: ""
    property string gpuGfxRangeText: ""
    property bool isLoadingClocks: false
    property bool isApplyingClock: false

    // 定时器用于延迟检查
    Timer {
        id: overlayCheckTimer
        interval: 100
        repeat: false
        onTriggered: {
            root._doCheckOverlayStatus()
        }
    }

    DankFlickable {
        anchors.fill: parent
        clip: true
        contentHeight: mainColumn.implicitHeight + Theme.spacingXL
        contentWidth: width

        Column {
            id: mainColumn
            topPadding: Theme.spacingM
            width: Math.min(550, parent.width - Theme.spacingL * 2)
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Theme.spacingXL

            // CPU Freq 选择区域
            Column {
                width: parent.width
                spacing: Theme.spacingM

                StyledText {
                    text: I18n.tr("CPU Frequency")
                    font.pixelSize: Theme.fontSizeLarge
                    font.weight: Font.Medium
                    color: Theme.surfaceText
                }

                DankDropdown {
                    id: cpuFreqDropdown
                    width: parent.width
                    text: I18n.tr("Preset Frequency")
                    description: I18n.tr("Select CPU frequency preset")
                    currentValue: root.currentCpuFreq !== "" ? (root.currentCpuFreq + " MHz") : I18n.tr("Loading...")
                    compactMode: false
                    options: ["800 MHz", "1000 MHz", "2000 MHz", "3000 MHz", "4600 MHz"]
                    enabled: root.currentCpuFreq !== ""

                    onValueChanged: value => {
                        root.setCpuFreq(value)
                    }
                }

                StyledText {
                    text: root.currentCpuFreq !== "" ? I18n.tr("Current: %1 MHz").arg(root.currentCpuFreq) : I18n.tr("Loading current frequency...")
                    font.pixelSize: Theme.fontSizeSmall
                    color: root.currentCpuFreq !== "" ? Theme.surfaceVariantText : Theme.primary
                }
            }

            // GPU Clock 选择区域
            Column {
                width: parent.width
                spacing: Theme.spacingM

                StyledText {
                    text: I18n.tr("GPU Clock")
                    font.pixelSize: Theme.fontSizeLarge
                    font.weight: Font.Medium
                    color: Theme.surfaceText
                }

                Row {
                    spacing: Theme.spacingS

                    DankButton {
                        text: I18n.tr("Low")
                        onClicked: {
                            const mem = "405 MHz"
                            const gfx = root.findClosestFreq(root.gpuGfxFreqs, 472)
                            SessionData.set("gpuMemClock", mem)
                            SessionData.set("gpuGfxClock", gfx)
                            root.updateClockRange("405 MHz", "405 MHz", gfx, gfx)
                            Proc.runCommand("gpuClockLow", ["sh", "-c", "user-nvidia-clock-set m 405 405 && user-nvidia-clock-set g 472 472"])
                        }
                    }
                    DankButton {
                        text: I18n.tr("Normal")
                        onClicked: {
                            const memMax = "7001 MHz"
                            const gfxMax = root.findClosestFreq(root.gpuGfxFreqs, 2100)
                            const gfxMin = root.findClosestFreq(root.gpuGfxFreqs, 472)
                            SessionData.set("gpuMemClock", memMax)
                            SessionData.set("gpuGfxClock", gfxMax)
                            root.updateClockRange("405 MHz", "7001 MHz", gfxMin, gfxMax)
                            Proc.runCommand("gpuClockNormal", ["sh", "-c", "user-nvidia-clock-set m 405 7001 && user-nvidia-clock-set g 472 2100"])
                        }
                    }
                    DankButton {
                        text: I18n.tr("High")
                        onClicked: {
                            const mem = "7001 MHz"
                            const gfx = root.findClosestFreq(root.gpuGfxFreqs, 2100)
                            SessionData.set("gpuMemClock", mem)
                            SessionData.set("gpuGfxClock", gfx)
                            root.updateClockRange("7001 MHz", "7001 MHz", gfx, gfx)
                            Proc.runCommand("gpuClockHigh", ["sh", "-c", "user-nvidia-clock-set m 7001 7001 && user-nvidia-clock-set g 2100 2100"])
                        }
                    }

                }

                Column {
                    spacing: 2

                    StyledText {
                        text: root.gpuMemRangeText
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                    }
                    StyledText {
                        text: root.gpuGfxRangeText
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                    }
                }

                DankDropdown {
                    id: gpuMemDropdown
                    width: parent.width
                    text: I18n.tr("Memory Clock")
                    description: I18n.tr("Select memory frequency")
                    currentValue: root.gpuMemFreqs.length > 0 ? SessionData.gpuMemClock : I18n.tr("Loading...")
                    options: root.gpuMemFreqs
                    enabled: root.gpuMemFreqs.length > 0 && !root.isApplyingClock

                    onValueChanged: value => {
                        SessionData.set("gpuMemClock", value)
                        root.updateClockRange(value, value, SessionData.gpuGfxClock, SessionData.gpuGfxClock)
                        root.applyCustomGpuClock()
                    }
                }

                DankDropdown {
                    id: gpuGfxDropdown
                    width: parent.width
                    text: I18n.tr("Graphics Clock")
                    description: I18n.tr("Select graphics frequency")
                    currentValue: root.gpuGfxFreqs.length > 0 ? SessionData.gpuGfxClock : I18n.tr("Loading...")
                    options: root.gpuGfxFreqs
                    enabled: root.gpuGfxFreqs.length > 0 && !root.isApplyingClock

                    onValueChanged: value => {
                        SessionData.set("gpuGfxClock", value)
                        root.updateClockRange(SessionData.gpuMemClock, SessionData.gpuMemClock, value, value)
                        root.applyCustomGpuClock()
                    }
                }

            }

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.outline
                opacity: 0.2
            }

            // Overlay 开关区域
            Column {
                width: parent.width
                spacing: Theme.spacingM

                StyledText {
                    text: I18n.tr("Display Settings")
                    font.pixelSize: Theme.fontSizeLarge
                    font.weight: Font.Medium
                    color: Theme.surfaceText
                }

                DankToggle {
                    id: overlayToggle
                    width: parent.width
                    text: I18n.tr("Activate Linux Overlay")
                    description: overlayStatusText.text
                    checked: root.overlayEnabled
                    enabled: !root.isSettingOverlay

                    onToggled: checked => {
                        root.setOverlay(checked)
                    }
                }

                StyledText {
                    id: overlayStatusText
                    text: {
                        if (root.isSettingOverlay) {
                            return I18n.tr("Updating...")
                        } else if (root.isCheckingOverlay) {
                            return I18n.tr("Checking status...")
                        } else {
                            return root.overlayEnabled ? I18n.tr("Running") : I18n.tr("Not running")
                        }
                    }
                    font.pixelSize: Theme.fontSizeSmall
                    color: root.overlayEnabled ? Theme.primary : Theme.surfaceVariantText
                    opacity: 0.8
                }
            }

            Item {
                width: 1
                height: Theme.spacingXL
            }
        }
    }

    // CPU Freq 设置函数
    function setCpuFreq(freqLabel) {
        // 解析频率值（例如 "800 MHz" -> 800）
        const freqMHz = parseInt(freqLabel.split(" ")[0])

        console.log("Setting CPU freq to:", freqLabel)

        // 调用 cpufreq 命令
        const cmd = `cpufreq ${freqMHz}M`
        Proc.runCommand("setCpuFreq", ["sh", "-c", cmd], (output, exitCode) => {
            console.log("cpufreq command output:", output, "exit code:", exitCode)
            if (exitCode === 0) {
                root.currentCpuFreq = String(freqMHz)
                console.log("CPU freq set successfully to", freqMHz, "MHz")
            } else {
                console.error("Failed to set CPU freq:", output)
            }
        })
    }

    // 获取当前 CPU Freq
    function getCurrentCpuFreq() {
        console.log("Getting current CPU freq...")
        Proc.runCommand("getCpuFreq", ["sh", "-c", "cpufreq"], (output, exitCode) => {
            console.log("cpufreq output:", output, "exit code:", exitCode)
            if (exitCode === 0) {
                // 解析输出，例如 "3.00 GHz" 或 "800 MHz"
                const trimmedOutput = output.trim()
                console.log("Raw output:", trimmedOutput)

                let freqMHz = 0
                if (trimmedOutput.includes("GHz")) {
                    // 解析 GHz 格式
                    const ghzMatch = trimmedOutput.match(/(\d+\.?\d*)\s*GHz/)
                    if (ghzMatch) {
                        freqMHz = Math.round(parseFloat(ghzMatch[1]) * 1000)
                    }
                } else if (trimmedOutput.includes("MHz")) {
                    // 解析 MHz 格式
                    const mhzMatch = trimmedOutput.match(/(\d+\.?\d*)\s*MHz/)
                    if (mhzMatch) {
                        freqMHz = Math.round(parseFloat(mhzMatch[1]))
                    }
                }

                if (freqMHz > 0) {
                    root.currentCpuFreq = String(freqMHz)
                    console.log("CPU freq updated to:", freqMHz, "MHz")
                }
            } else {
                console.error("Failed to get CPU freq:", output)
            }
        })
    }

    // Overlay 开关函数
    function setOverlay(enabled) {
        console.log("Setting overlay to:", enabled)
        root.isSettingOverlay = true

        if (enabled) {
            // 后台启动 activate-linux-c
            console.log("Starting activate-linux-c in background...")
            Quickshell.execDetached(["activate-linux-c"])
            // 立即设置延迟检查
            overlayCheckTimer.start()
        } else {
            // 杀死 activate-linux 进程
            console.log("Stopping activate-linux...")
            Proc.runCommand("stopOverlay", ["pkill", "activate-linux"], (output, exitCode) => {
                console.log("pkill exit code:", exitCode)
                // 停止后延迟检查
                overlayCheckTimer.start()
            })
        }
    }

    // 实际检查 overlay 状态（内部函数）
    function _doCheckOverlayStatus() {
        console.log("Checking overlay status...")
        root.isCheckingOverlay = true

        Proc.runCommand("checkOverlay", ["pgrep", "activate-linux"], (output, exitCode) => {
            console.log("pgrep output:", output, "pgrep exit code:", exitCode)
            // pgrep 返回 0 表示找到进程，非 0 表示未找到
            root.overlayEnabled = (exitCode === 0)
            root.isCheckingOverlay = false
            root.isSettingOverlay = false
            console.log("Overlay status check complete:", root.overlayEnabled ? "enabled" : "disabled")
        })
    }

    function updateClockRange(memMin, memMax, gfxMin, gfxMax) {
        root.gpuMemMin = memMin
        root.gpuMemMax = memMax
        root.gpuGfxMin = gfxMin
        root.gpuGfxMax = gfxMax
        root.gpuMemRangeText = "Mem  " + memMin + " – " + memMax
        root.gpuGfxRangeText = "Gfx  " + gfxMin + " – " + gfxMax
        SessionData.set("gpuMemClockMin", memMin)
        SessionData.set("gpuMemClockMax", memMax)
        SessionData.set("gpuGfxClockMin", gfxMin)
        SessionData.set("gpuGfxClockMax", gfxMax)
    }

    // 在频率列表中找到最接近的目标值
    function findClosestFreq(freqs, targetMhz) {
        if (freqs.length === 0)
            return ""
        let best = freqs[0]
        let bestDiff = Math.abs(parseInt(freqs[0]) - targetMhz)
        for (let i = 1; i < freqs.length; i++) {
            const diff = Math.abs(parseInt(freqs[i]) - targetMhz)
            if (diff < bestDiff) {
                bestDiff = diff
                best = freqs[i]
            }
        }
        return best
    }

    // 加载 GPU 支持的频率
    function loadSupportedClocks() {
        if (root.isLoadingClocks)
            return
        root.isLoadingClocks = true
        console.log("Loading GPU supported clocks...")
        Proc.runCommand("getGpuClocks", ["sh", "-c", "nvidia-smi -q -d supported_clocks"], (output, exitCode) => {
            if (exitCode !== 0) {
                console.error("Failed to get GPU supported clocks:", output)
                root.isLoadingClocks = false
                return
            }
            const memSet = new Set()
            const gfxSet = new Set()
            const lines = output.split("\n")
            for (let i = 0; i < lines.length; i++) {
                const line = lines[i]
                const memMatch = line.match(/^\s*Memory\s*:\s*(\d+)\s*MHz/)
                if (memMatch) {
                    memSet.add(parseInt(memMatch[1]))
                    continue
                }
                const gfxMatch = line.match(/^\s*Graphics\s*:\s*(\d+)\s*MHz/)
                if (gfxMatch) {
                    gfxSet.add(parseInt(gfxMatch[1]))
                }
            }
            const memArr = Array.from(memSet).sort((a, b) => b - a)
            let gfxArr = Array.from(gfxSet).sort((a, b) => b - a)
            // 只取 ~10 档
            if (gfxArr.length > 10) {
                const step = Math.floor(gfxArr.length / 10)
                gfxArr = gfxArr.filter((_, i) => i % step === 0)
            }
            root.gpuMemFreqs = memArr.map(f => f + " MHz")
            root.gpuGfxFreqs = gfxArr.map(f => f + " MHz")
            // 只在首次或 persisted 值不在新列表中时设默认值
            if (memArr.length > 0) {
                if (SessionData.gpuMemClock === "" || !root.gpuMemFreqs.includes(SessionData.gpuMemClock)) {
                    SessionData.set("gpuMemClock", root.gpuMemFreqs[0])
                }
                if (SessionData.gpuGfxClock === "" || !root.gpuGfxFreqs.includes(SessionData.gpuGfxClock)) {
                    SessionData.set("gpuGfxClock", root.gpuGfxFreqs[0])
                }
                const memMin = SessionData.gpuMemClockMin !== "" ? SessionData.gpuMemClockMin : SessionData.gpuMemClock
                const memMax = SessionData.gpuMemClockMax !== "" ? SessionData.gpuMemClockMax : SessionData.gpuMemClock
                const gfxMin = SessionData.gpuGfxClockMin !== "" ? SessionData.gpuGfxClockMin : SessionData.gpuGfxClock
                const gfxMax = SessionData.gpuGfxClockMax !== "" ? SessionData.gpuGfxClockMax : SessionData.gpuGfxClock
                root.updateClockRange(memMin, memMax, gfxMin, gfxMax)
            }
            root.isLoadingClocks = false
            console.log("GPU supported clocks loaded:", memArr.length, "memories,", gfxArr.length, "graphics")
        })
    }

    // 应用自定义 GPU Clock
    function applyCustomGpuClock() {
        const memMin = parseInt(root.gpuMemMin)
        const memMax = parseInt(root.gpuMemMax)
        const gfxMin = parseInt(root.gpuGfxMin)
        const gfxMax = parseInt(root.gpuGfxMax)
        if (!memMin || !memMax || !gfxMin || !gfxMax) {
            console.warn("No GPU clock frequencies selected")
            return
        }
        root.isApplyingClock = true
        console.log("Applying GPU clock: Mem", memMin, "-", memMax, "MHz, Graphics", gfxMin, "-", gfxMax, "MHz")
        const cmd = `user-nvidia-clock-set m ${memMin} ${memMax} && user-nvidia-clock-set g ${gfxMin} ${gfxMax}`
        Proc.runCommand("applyGpuClock", ["sh", "-c", cmd], (output, exitCode) => {
            root.isApplyingClock = false
            if (exitCode === 0) {
                console.log("GPU clock applied successfully")
            } else {
                console.error("Failed to apply GPU clock:", output)
            }
        })
    }

    // 检查 overlay 状态（公开函数）
    function checkOverlayStatus() {
        console.log("Check overlay status called")
        root.isCheckingOverlay = true
        root._doCheckOverlayStatus()
    }

    Component.onCompleted: {
        console.log("SystemTab initialized")
        // 初始化时获取当前 CPU freq、overlay 状态和 GPU clocks
        root.getCurrentCpuFreq()
        root.checkOverlayStatus()
        root.loadSupportedClocks()
    }

    // 当 tab 变为可见时重新检查状态
    onVisibleChanged: {
        if (visible) {
            console.log("SystemTab visible, refreshing...")
            root.getCurrentCpuFreq()
            root.checkOverlayStatus()
            root.loadSupportedClocks()
        }
    }
}

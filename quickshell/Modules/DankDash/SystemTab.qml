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

    // 检查 overlay 状态（公开函数）
    function checkOverlayStatus() {
        console.log("Check overlay status called")
        root.isCheckingOverlay = true
        root._doCheckOverlayStatus()
    }

    Component.onCompleted: {
        console.log("SystemTab initialized")
        // 初始化时获取当前 CPU freq 和 overlay 状态
        root.getCurrentCpuFreq()
        root.checkOverlayStatus()
    }

    // 当 tab 变为可见时重新检查状态
    onVisibleChanged: {
        if (visible) {
            console.log("SystemTab visible, refreshing...")
            root.getCurrentCpuFreq()
            root.checkOverlayStatus()
        }
    }
}

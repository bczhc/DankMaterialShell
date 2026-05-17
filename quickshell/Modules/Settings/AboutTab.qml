import QtQuick
import QtQuick.Effects
import qs.Common
import qs.Services
import qs.Widgets

Item {
    id: aboutTab

    LayoutMirroring.enabled: I18n.isRtl
    LayoutMirroring.childrenInherit: true

    property bool isHyprland: CompositorService.isHyprland
    property bool isNiri: CompositorService.isNiri
    property bool isSway: CompositorService.isSway
    property bool isScroll: CompositorService.isScroll
    property bool isMiracle: CompositorService.isMiracle
    property bool isDwl: CompositorService.isDwl
    property bool isLabwc: CompositorService.isLabwc

    property string compositorName: {
        if (isHyprland)
            return "hyprland";
        if (isSway)
            return "sway";
        if (isScroll)
            return "scroll";
        if (isMiracle)
            return "miracle";
        if (isDwl)
            return "mangowc";
        if (isLabwc)
            return "labwc";
        return "niri";
    }

    property string compositorLogo: {
        if (isHyprland)
            return "/assets/hyprland.svg";
        if (isSway)
            return "/assets/sway.svg";
        if (isScroll)
            return "/assets/sway.svg";
        if (isMiracle)
            return "/assets/miraclewm.svg";
        if (isDwl)
            return "/assets/mango.png";
        if (isLabwc)
            return "/assets/labwc.png";
        return "/assets/niri.svg";
    }

    property string compositorUrl: {
        if (isHyprland)
            return "https://hypr.land";
        if (isSway)
            return "https://swaywm.org";
        if (isScroll)
            return "https://github.com/dawsers/scroll";
        if (isMiracle)
            return "https://github.com/miracle-wm-org/miracle-wm";
        if (isDwl)
            return "https://github.com/DreamMaoMao/mangowc";
        if (isLabwc)
            return "https://labwc.github.io/";
        return "https://github.com/niri-wm/niri";
    }

    property string compositorTooltip: {
        if (isHyprland)
            return I18n.tr("Hyprland Website");
        if (isSway)
            return I18n.tr("Sway Website");
        if (isScroll)
            return I18n.tr("Scroll GitHub");
        if (isMiracle)
            return I18n.tr("Scroll GitHub");
        if (isDwl)
            return I18n.tr("mangowc GitHub");
        if (isLabwc)
            return I18n.tr("LabWC Website");
        return I18n.tr("niri GitHub");
    }

    property string dmsDiscordUrl: "https://discord.gg/ppWTpKmPgT"
    property string dmsDiscordTooltip: I18n.tr("niri/dms Discord")

    property string compositorDiscordUrl: {
        if (isHyprland)
            return "https://discord.com/invite/hQ9XvMUjjr";
        if (isDwl)
            return "https://discord.gg/CPjbDxesh5";
        return "";
    }

    property string compositorDiscordTooltip: {
        if (isHyprland)
            return I18n.tr("Hyprland Discord Server");
        if (isDwl)
            return I18n.tr("mangowc Discord Server");
        return "";
    }

    property string redditUrl: "https://reddit.com/r/niri"
    property string redditTooltip: I18n.tr("r/niri Subreddit")

    property string ircUrl: "https://web.libera.chat/gamja/?channels=#labwc"
    property string ircTooltip: I18n.tr("LabWC IRC Channel")

    property bool showMatrix: isNiri && !isHyprland && !isSway && !isScroll && !isMiracle && !isDwl && !isLabwc
    property bool showCompositorDiscord: isHyprland || isDwl
    property bool showReddit: isNiri && !isHyprland && !isSway && !isScroll && !isMiracle && !isDwl && !isLabwc
    property bool showIrc: isLabwc

    property string archOS: ""
    property string archHost: ""
    property string archDevice: ""
    property string archKernel: ""
    property string archUptime: ""
    property string archPackages: ""
    property string archShell: ""
    property string archCompositor: ""
    property string archDisplay: ""
    property string archDisplay2: ""
    property string archCPU: ""
    property string archGPU: ""
    property string archGPU2: ""
    property string archMemory: ""

    // Configurable sizes
    property real archLogoSize: 128
    property real archFontSize: 32

    Component.onCompleted: {
        Proc.runCommand("arch-os", ["sh", "-c", "cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d'\"' -f2"], (out, code) => {
            if (code === 0 && out.trim()) archOS = out.trim();
        });
        Proc.runCommand("arch-host", ["sh", "-c", "cat /sys/devices/virtual/dmi/id/product_name 2>/dev/null || echo -n"], (out, code) => {
            if (code === 0 && out.trim()) archHost = out.trim();
        });
        Proc.runCommand("arch-device", ["uname", "-n"], (out, code) => {
            if (code === 0) archDevice = out.trim();
        });
        Proc.runCommand("arch-kernel", ["uname", "-r"], (out, code) => {
            if (code === 0) archKernel = out.trim();
        });
        Proc.runCommand("arch-uptime", ["uptime", "-p"], (out, code) => {
            if (code === 0) archUptime = out.trim().replace(/^up /, "");
        });
        Proc.runCommand("arch-pkgs", ["sh", "-c", "pacman -Q 2>/dev/null | wc -l"], (out, code) => {
            if (code === 0) archPackages = out.trim() + " (pacman)";
        });
        Proc.runCommand("arch-shell", ["sh", "-c", "basename ${SHELL} 2>/dev/null || echo $SHELL"], (out, code) => {
            if (code === 0 && out.trim()) archShell = out.trim();
        });
        Proc.runCommand("arch-cpu", ["sh", "-c", "grep 'model name' /proc/cpuinfo 2>/dev/null | head -1 | cut -d':' -f2- | xargs"], (out, code) => {
            if (code === 0 && out.trim()) archCPU = out.trim();
        });
        Proc.runCommand("arch-gpu", ["sh", "-c", "lspci 2>/dev/null | grep -iE 'vga|3d|display' | cut -d':' -f3- | sed 's/^ *//'"], (out, code) => {
            if (code === 0 && out.trim()) {
                var lines = out.trim().split("\n");
                archGPU = lines[0] || "";
                archGPU2 = lines[1] || "";
            }
        });
        Proc.runCommand("arch-mem", ["sh", "-c", "free -b 2>/dev/null | awk '/^Mem:/ {printf \"%.1f GiB\", $2/1073741824}'"], (out, code) => {
            if (code === 0 && out.trim()) archMemory = out.trim();
        });
        var compVerCmd = compositorName + " --version 2>/dev/null | head -1";
        if (compositorName === "hyprland") compVerCmd = "Hyprland --version 2>/dev/null | head -1";
        Proc.runCommand("arch-compositor", ["sh", "-c", compVerCmd], (out, code) => {
            if (code === 0 && out.trim()) archCompositor = out.trim();
            else archCompositor = compositorName;
        });
        Proc.runCommand("arch-display", ["sh", "-c", "niri msg outputs 2>/dev/null | awk 'function flush(){if(c&&m){di=int(sqrt(w*w+h*h)/25.4+0.5);printf\"%s @ %.0f Hz, %d\\\", %.2fx\\n\",m,r,di,s}} /^Output/{flush();c=$NF;gsub(/[()]/,\"\",c);m=\"\";r=\"\";w=0;h=0;s=1} /Current mode:/{m=$3;r=$5} /Physical size:/{split($3,d,\"x\");w=d[1]+0;h=d[2]+0} /Scale:/{s=$2+0} END{flush()}'"], (out, code) => {
            if (code === 0 && out.trim()) {
                var lines = out.trim().split("\n");
                archDisplay = lines[0] || "";
                archDisplay2 = lines[1] || "";
            }
        });
    }

    component InfoRow: Row {
        property string label: ""
        property string value: ""

        width: parent ? parent.width : 0
        spacing: Theme.spacingL
        visible: value !== ""

        StyledText {
            text: label
            font.pixelSize: Theme.fontSizeMedium
            color: Theme.surfaceVariantText
            width: 80
        }
        StyledText {
            text: value
            font.pixelSize: Theme.fontSizeMedium
            color: Theme.surfaceText
            width: parent ? parent.width - 80 - Theme.spacingL : 0
            elide: Text.ElideRight
        }
    }

    DankFlickable {
        anchors.fill: parent
        clip: true
        contentHeight: mainColumn.height + Theme.spacingXL
        contentWidth: width

        Column {
            id: mainColumn
            topPadding: 4

            width: Math.min(550, parent.width - Theme.spacingL * 2)
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Theme.spacingXL

            // Combined Logo Card
            StyledRect {
                width: parent.width
                height: logoSection.implicitHeight + Theme.spacingL * 2
                radius: Theme.cornerRadius
                color: Theme.surfaceContainerHigh
                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
                border.width: 0

                Column {
                    id: logoSection
                    anchors.fill: parent
                    anchors.margins: Theme.spacingL
                    spacing: Theme.spacingM

                    Column {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: Theme.spacingM

                        // Arch Linux
                        Row {
                            spacing: Theme.spacingM

                            Item { width: archLogoSize + 8; height: archLogoSize; anchors.verticalCenter: parent.verticalCenter
                                Image {
                                    //source: "file:///usr/share/icons/archlinux.png"
                                    source: "file:///usr/share/icons/dms-archlinux-logo-tm.svg"
                                    width: archLogoSize; height: archLogoSize
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                    anchors.centerIn: parent
                                }
                            }

                            Column { anchors.verticalCenter: parent.verticalCenter
                                StyledText { text: "Arch Linux"; font.pixelSize: archFontSize; font.weight: Font.Bold; color: Theme.surfaceText }
                                StyledText { text: "A simple, lightweight Linux distribution"; font.pixelSize: Theme.fontSizeSmall; color: Theme.surfaceVariantText }
                            }
                        }

                        Rectangle {
                            width: 280
                            height: 1
                            anchors.horizontalCenter: parent.horizontalCenter
                            color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.15)
                        }

                        // DANK LINUX
                        Row {
                            spacing: Theme.spacingM

                            Item { width: archLogoSize + 8; height: archLogoSize; anchors.verticalCenter: parent.verticalCenter
                                Image {
                                    id: logoImage
                                    anchors.centerIn: parent
                                    width: archLogoSize; height: archLogoSize * (569.94629 / 506.50931)
                                    fillMode: Image.PreserveAspectFit; smooth: true; mipmap: true; asynchronous: true
                                    source: "file://" + Theme.shellDir + "/assets/danklogonormal.svg"
                                    layer.enabled: true; layer.smooth: true; layer.mipmap: true
                                    layer.effect: MultiEffect { saturation: 0; colorization: 1; colorizationColor: Theme.primary }
                                }
                            }

                            Column { anchors.verticalCenter: parent.verticalCenter
                                Text { text: "DANK LINUX"; font.pixelSize: 28; font.weight: Font.Bold; font.family: interFont.name; color: Theme.surfaceText; antialiasing: true }
                                StyledText {
                                    text: {
                                        if (!SystemUpdateService.shellVersion && !DMSService.cliVersion) return "dms";
                                        let v = SystemUpdateService.shellVersion || DMSService.cliVersion || "";
                                        let m = v.match(/^([\d.]+)\+git(\d+)\./);
                                        if (m) return `dms (git) v${m[1]}-${m[2]}`;
                                        m = v.match(/^([\d.]+)$/);
                                        if (m) return `dms v${m[1]}`;
                                        return `dms ${v}`;
                                    }
                                    font.pixelSize: Theme.fontSizeSmall; color: Theme.surfaceVariantText
                                }
                            }
                        }
                    }

                    FontLoader {
                        id: interFont
                        source: Qt.resolvedUrl("../../assets/fonts/inter/InterVariable.ttf")
                    }
                }
            }

            // Software Info
            StyledRect {
                width: parent.width
                height: softwareSection.implicitHeight + Theme.spacingL * 2
                radius: Theme.cornerRadius
                color: Theme.surfaceContainerHigh
                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
                border.width: 0

                Column {
                    id: softwareSection
                    anchors.fill: parent
                    anchors.margins: Theme.spacingL
                    spacing: Theme.spacingS

                    Row {
                        width: parent.width
                        spacing: Theme.spacingM
                        DankIcon {
                            name: "terminal"
                            size: Theme.iconSize
                            color: Theme.primary
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        StyledText {
                            text: "Software"
                            font.pixelSize: Theme.fontSizeLarge
                            font.weight: Font.Medium
                            color: Theme.surfaceText
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Item { width: 1; height: 1 }

                    InfoRow { label: "OS"; value: archOS }
                    InfoRow { label: "Device"; value: archDevice }
                    InfoRow { label: "Host"; value: archHost }
                    InfoRow { label: "Kernel"; value: archKernel }
                    InfoRow { label: "Uptime"; value: archUptime }
                    InfoRow { label: "Packages"; value: archPackages }
                    InfoRow { label: "Shell"; value: archShell }
                    InfoRow { label: "Compositor"; value: archCompositor }
                    InfoRow { label: "DMS"; value: SystemUpdateService.shellVersion || DMSService.cliVersion || "" }
                }
            }

            // Hardware Info
            StyledRect {
                width: parent.width
                height: hardwareSection.implicitHeight + Theme.spacingL * 2
                radius: Theme.cornerRadius
                color: Theme.surfaceContainerHigh
                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
                border.width: 0

                Column {
                    id: hardwareSection
                    anchors.fill: parent
                    anchors.margins: Theme.spacingL
                    spacing: Theme.spacingS

                    Row {
                        width: parent.width
                        spacing: Theme.spacingM
                        DankIcon {
                            name: "memory"
                            size: Theme.iconSize
                            color: Theme.primary
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        StyledText {
                            text: "Hardware"
                            font.pixelSize: Theme.fontSizeLarge
                            font.weight: Font.Medium
                            color: Theme.surfaceText
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Item { width: 1; height: 1 }

                    InfoRow { label: "Display"; value: archDisplay }
                    InfoRow { label: "Display"; value: archDisplay2 }
                    InfoRow { label: "Memory"; value: archMemory }
                    InfoRow { label: "CPU"; value: archCPU }
                    InfoRow { label: "GPU"; value: archGPU }
                    InfoRow { label: "GPU"; value: archGPU2 }
                }
            }

            // Resources
            StyledRect {
                width: parent.width
                height: resourceSection.implicitHeight + Theme.spacingL * 2
                radius: Theme.cornerRadius
                color: Theme.surfaceContainerHigh
                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
                border.width: 0

                Column {
                    id: resourceSection
                    anchors.fill: parent
                    anchors.margins: Theme.spacingL
                    spacing: Theme.spacingM

                    Row {
                        width: parent.width
                        spacing: Theme.spacingM
                        DankIcon {
                            name: "link"
                            size: Theme.iconSize
                            color: Theme.primary
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        StyledText {
                            text: I18n.tr("Resources")
                            font.pixelSize: Theme.fontSizeLarge
                            font.weight: Font.Medium
                            color: Theme.surfaceText
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Row {
                        id: resourceButtonsRow
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: Theme.spacingS

                        property bool compactMode: parent.width < 450

                        DankButton {
                            id: docsButton
                            text: resourceButtonsRow.compactMode ? "" : I18n.tr("Docs")
                            iconName: "menu_book"
                            iconSize: 18
                            backgroundColor: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.08)
                            textColor: Theme.surfaceText
                            onClicked: Qt.openUrlExternally("https://danklinux.com/docs")
                            onHoveredChanged: {
                                if (hovered)
                                    resourceTooltip.show(resourceButtonsRow.compactMode ? I18n.tr("Docs") + " - danklinux.com/docs" : "danklinux.com/docs", docsButton, 0, 0, "bottom");
                                else
                                    resourceTooltip.hide();
                            }
                        }

                        DankButton {
                            id: pluginsButton
                            text: resourceButtonsRow.compactMode ? "" : I18n.tr("Plugins")
                            iconName: "extension"
                            iconSize: 18
                            backgroundColor: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.08)
                            textColor: Theme.surfaceText
                            onClicked: Qt.openUrlExternally("https://plugins.danklinux.com")
                            onHoveredChanged: {
                                if (hovered)
                                    resourceTooltip.show(resourceButtonsRow.compactMode ? I18n.tr("Plugins") + " - plugins.danklinux.com" : "plugins.danklinux.com", pluginsButton, 0, 0, "bottom");
                                else
                                    resourceTooltip.hide();
                            }
                        }

                        DankButton {
                            id: githubButton
                            text: resourceButtonsRow.compactMode ? "" : I18n.tr("GitHub")
                            iconName: "code"
                            iconSize: 18
                            backgroundColor: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.08)
                            textColor: Theme.surfaceText
                            onClicked: Qt.openUrlExternally("https://github.com/AvengeMedia/DankMaterialShell")
                            onHoveredChanged: {
                                if (hovered)
                                    resourceTooltip.show(resourceButtonsRow.compactMode ? "GitHub - AvengeMedia/DankMaterialShell" : "github.com/AvengeMedia/DankMaterialShell", githubButton, 0, 0, "bottom");
                                else
                                    resourceTooltip.hide();
                            }
                        }

                        DankButton {
                            id: kofiButton
                            text: resourceButtonsRow.compactMode ? "" : I18n.tr("Ko-fi")
                            iconName: "favorite"
                            iconSize: 18
                            backgroundColor: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)
                            textColor: Theme.primary
                            onClicked: Qt.openUrlExternally("https://ko-fi.com/danklinux")
                            onHoveredChanged: {
                                if (hovered)
                                    resourceTooltip.show(resourceButtonsRow.compactMode ? I18n.tr("Ko-fi") + " - ko-fi.com/danklinux" : "ko-fi.com/danklinux", kofiButton, 0, 0, "bottom");
                                else
                                    resourceTooltip.hide();
                            }
                        }
                    }

                    DankTooltipV2 {
                        id: resourceTooltip
                    }

                    Item {
                        id: communityIcons
                        anchors.horizontalCenter: parent.horizontalCenter
                        height: 24
                        width: {
                            let baseWidth = compositorButton.width + dmsDiscordButton.width + Theme.spacingM;
                            if (showMatrix) baseWidth += matrixButton.width + 4;
                            if (showIrc) baseWidth += ircButton.width + Theme.spacingM;
                            if (showCompositorDiscord) baseWidth += compositorDiscordButton.width + Theme.spacingM;
                            if (showReddit) baseWidth += redditButton.width + Theme.spacingM;
                            return baseWidth;
                        }

                        Item {
                            id: compositorButton
                            width: 24; height: 24
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.verticalCenterOffset: -2
                            x: 0
                            property bool hovered: false
                            property string tooltipText: compositorTooltip
                            Image {
                                anchors.fill: parent
                                source: Qt.resolvedUrl(".").toString().replace("file://", "").replace("/Modules/Settings/", "") + compositorLogo
                                sourceSize: Qt.size(24, 24)
                                smooth: true
                                fillMode: Image.PreserveAspectFit
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                onEntered: parent.hovered = true
                                onExited: parent.hovered = false
                                onClicked: Qt.openUrlExternally(compositorUrl)
                            }
                        }

                        Item {
                            id: matrixButton
                            width: 30; height: 24
                            x: compositorButton.x + compositorButton.width + 4
                            visible: showMatrix
                            property bool hovered: false
                            property string tooltipText: I18n.tr("niri Matrix Chat")
                            Image {
                                anchors.fill: parent
                                source: Qt.resolvedUrl(".").toString().replace("file://", "").replace("/Modules/Settings/", "") + "/assets/matrix-logo-white.svg"
                                sourceSize: Qt.size(28, 18)
                                smooth: true
                                fillMode: Image.PreserveAspectFit
                                layer.enabled: true
                                layer.effect: MultiEffect {
                                    colorization: 1
                                    colorizationColor: Theme.surfaceText
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                onEntered: parent.hovered = true
                                onExited: parent.hovered = false
                                onClicked: Qt.openUrlExternally("https://matrix.to/#/#niri:matrix.org")
                            }
                        }

                        Item {
                            id: ircButton
                            width: 24; height: 24
                            x: compositorButton.x + compositorButton.width + Theme.spacingM
                            anchors.verticalCenter: parent.verticalCenter
                            visible: showIrc
                            property bool hovered: false
                            property string tooltipText: ircTooltip
                            DankIcon {
                                anchors.centerIn: parent
                                name: "forum"; size: 20
                                color: Theme.surfaceText
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                onEntered: parent.hovered = true
                                onExited: parent.hovered = false
                                onClicked: Qt.openUrlExternally(ircUrl)
                            }
                        }

                        Item {
                            id: dmsDiscordButton
                            width: 20; height: 20
                            x: {
                                if (showMatrix) return matrixButton.x + matrixButton.width + Theme.spacingM;
                                if (showIrc) return ircButton.x + ircButton.width + Theme.spacingM;
                                return compositorButton.x + compositorButton.width + Theme.spacingM;
                            }
                            anchors.verticalCenter: parent.verticalCenter
                            property bool hovered: false
                            property string tooltipText: dmsDiscordTooltip
                            Image {
                                anchors.fill: parent
                                source: Qt.resolvedUrl(".").toString().replace("file://", "").replace("/Modules/Settings/", "") + "/assets/discord.svg"
                                sourceSize: Qt.size(20, 20)
                                smooth: true
                                fillMode: Image.PreserveAspectFit
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                onEntered: parent.hovered = true
                                onExited: parent.hovered = false
                                onClicked: Qt.openUrlExternally(dmsDiscordUrl)
                            }
                        }

                        Item {
                            id: compositorDiscordButton
                            width: 20; height: 20
                            x: dmsDiscordButton.x + dmsDiscordButton.width + Theme.spacingM
                            anchors.verticalCenter: parent.verticalCenter
                            visible: showCompositorDiscord
                            property bool hovered: false
                            property string tooltipText: compositorDiscordTooltip
                            Image {
                                anchors.fill: parent
                                source: Qt.resolvedUrl(".").toString().replace("file://", "").replace("/Modules/Settings/", "") + "/assets/discord.svg"
                                sourceSize: Qt.size(20, 20)
                                smooth: true
                                fillMode: Image.PreserveAspectFit
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                onEntered: parent.hovered = true
                                onExited: parent.hovered = false
                                onClicked: Qt.openUrlExternally(compositorDiscordUrl)
                            }
                        }

                        Item {
                            id: redditButton
                            width: 20; height: 20
                            x: showCompositorDiscord ? compositorDiscordButton.x + compositorDiscordButton.width + Theme.spacingM : dmsDiscordButton.x + dmsDiscordButton.width + Theme.spacingM
                            anchors.verticalCenter: parent.verticalCenter
                            visible: showReddit
                            property bool hovered: false
                            property string tooltipText: redditTooltip
                            Image {
                                anchors.fill: parent
                                source: Qt.resolvedUrl(".").toString().replace("file://", "").replace("/Modules/Settings/", "") + "/assets/reddit.svg"
                                sourceSize: Qt.size(20, 20)
                                smooth: true
                                fillMode: Image.PreserveAspectFit
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                onEntered: parent.hovered = true
                                onExited: parent.hovered = false
                                onClicked: Qt.openUrlExternally(redditUrl)
                            }
                        }
                    }
                }
            }

            // Project Information
            StyledRect {
                width: parent.width
                height: projectSection.implicitHeight + Theme.spacingL * 2
                radius: Theme.cornerRadius
                color: Theme.surfaceContainerHigh
                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
                border.width: 0

                Column {
                    id: projectSection

                    anchors.fill: parent
                    anchors.margins: Theme.spacingL
                    spacing: Theme.spacingM

                    Row {
                        width: parent.width
                        spacing: Theme.spacingM

                        DankIcon {
                            name: "info"
                            size: Theme.iconSize
                            color: Theme.primary
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        StyledText {
                            text: I18n.tr("About")
                            font.pixelSize: Theme.fontSizeLarge
                            font.weight: Font.Medium
                            color: Theme.surfaceText
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    StyledText {
                        text: I18n.tr('dms is a highly customizable, modern desktop shell with a <a href="https://m3.material.io/" style="text-decoration:none; color:%1;">material 3 inspired</a> design.<br /><br/>It is built with <a href="https://quickshell.org" style="text-decoration:none; color:%1;">Quickshell</a>, a QT6 framework for building desktop shells, and <a href="https://go.dev" style="text-decoration:none; color:%1;">Go</a>, a statically typed, compiled programming language.').arg(Theme.primary)
                        textFormat: Text.RichText
                        font.pixelSize: Theme.fontSizeMedium
                        linkColor: Theme.primary
                        onLinkActivated: url => Qt.openUrlExternally(url)
                        color: Theme.surfaceVariantText
                        width: parent.width
                        wrapMode: Text.WordWrap

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
                            acceptedButtons: Qt.NoButton
                            propagateComposedEvents: true
                        }
                    }
                }
            }

            StyledRect {
                visible: DMSService.isConnected
                width: parent.width
                height: backendSection.implicitHeight + Theme.spacingL * 2
                radius: Theme.cornerRadius
                color: Theme.surfaceContainerHigh
                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
                border.width: 0

                Column {
                    id: backendSection

                    anchors.fill: parent
                    anchors.margins: Theme.spacingL
                    spacing: Theme.spacingM

                    Row {
                        width: parent.width
                        spacing: Theme.spacingM

                        DankIcon {
                            name: "dns"
                            size: Theme.iconSize
                            color: Theme.primary
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        StyledText {
                            text: I18n.tr("Backend")
                            font.pixelSize: Theme.fontSizeLarge
                            font.weight: Font.Medium
                            color: Theme.surfaceText
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Row {
                        anchors.left: parent.left
                        spacing: Theme.spacingL

                        Column {
                            spacing: 2

                            StyledText {
                                text: I18n.tr("Version")
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceVariantText
                                horizontalAlignment: Text.AlignLeft
                            }

                            StyledText {
                                text: DMSService.cliVersion || "—"
                                font.pixelSize: Theme.fontSizeMedium
                                font.weight: Font.Medium
                                color: Theme.surfaceText
                                horizontalAlignment: Text.AlignLeft
                            }
                        }

                        Rectangle {
                            width: 1
                            height: 32
                            color: Theme.outlineVariant
                        }

                        Column {
                            spacing: 2

                            StyledText {
                                text: I18n.tr("API")
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceVariantText
                                horizontalAlignment: Text.AlignLeft
                            }

                            StyledText {
                                text: `v${DMSService.apiVersion}`
                                font.pixelSize: Theme.fontSizeMedium
                                font.weight: Font.Medium
                                color: Theme.surfaceText
                                horizontalAlignment: Text.AlignLeft
                            }
                        }

                        Rectangle {
                            width: 1
                            height: 32
                            color: Theme.outlineVariant
                        }

                        Column {
                            spacing: 2

                            StyledText {
                                text: I18n.tr("Status")
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceVariantText
                                horizontalAlignment: Text.AlignLeft
                            }

                            Row {
                                spacing: 4

                                Rectangle {
                                    width: 8
                                    height: 8
                                    radius: 4
                                    color: Theme.success
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                StyledText {
                                    text: I18n.tr("Connected")
                                    font.pixelSize: Theme.fontSizeMedium
                                    font.weight: Font.Medium
                                    color: Theme.surfaceText
                                    horizontalAlignment: Text.AlignLeft
                                }
                            }
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: Theme.spacingS
                        visible: DMSService.capabilities.length > 0

                        StyledText {
                            text: I18n.tr("Capabilities")
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceVariantText
                            width: parent.width
                            horizontalAlignment: Text.AlignLeft
                        }

                        Flow {
                            width: parent.width
                            spacing: 6

                            Repeater {
                                model: DMSService.capabilities

                                Rectangle {
                                    width: capText.implicitWidth + 16
                                    height: 26
                                    radius: 13
                                    color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)

                                    StyledText {
                                        id: capText
                                        anchors.centerIn: parent
                                        text: modelData
                                        font.pixelSize: Theme.fontSizeSmall
                                        color: Theme.primary
                                    }
                                }
                            }
                        }
                    }
                }
            }

            StyledRect {
                width: parent.width
                height: toolsSection.implicitHeight + Theme.spacingL * 2
                radius: Theme.cornerRadius
                color: Theme.surfaceContainerHigh
                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
                border.width: 0

                Column {
                    id: toolsSection

                    anchors.fill: parent
                    anchors.margins: Theme.spacingL
                    spacing: Theme.spacingM

                    Row {
                        width: parent.width
                        spacing: Theme.spacingM

                        DankIcon {
                            name: "build"
                            size: Theme.iconSize
                            color: Theme.primary
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        StyledText {
                            text: I18n.tr("Tools")
                            font.pixelSize: Theme.fontSizeLarge
                            font.weight: Font.Medium
                            color: Theme.surfaceText
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Row {
                        anchors.left: parent.left
                        spacing: Theme.spacingS

                        DankButton {
                            text: I18n.tr("Show Welcome")
                            iconName: "waving_hand"
                            backgroundColor: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.08)
                            textColor: Theme.surfaceText
                            onClicked: FirstLaunchService.showWelcome()
                        }

                        DankButton {
                            text: I18n.tr("System Check")
                            iconName: "vital_signs"
                            backgroundColor: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.08)
                            textColor: Theme.surfaceText
                            onClicked: FirstLaunchService.showDoctor()
                        }
                    }
                }
            }

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: I18n.tr('<a href="https://github.com/AvengeMedia/DankMaterialShell/blob/master/LICENSE" style="text-decoration:none; color:%1;">MIT License</a>').arg(Theme.surfaceVariantText)
                font.pixelSize: Theme.fontSizeMedium
                color: Theme.surfaceVariantText
                textFormat: Text.RichText
                wrapMode: Text.NoWrap
                onLinkActivated: url => Qt.openUrlExternally(url)

                MouseArea {
                    anchors.fill: parent
                    cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
                    acceptedButtons: Qt.NoButton
                    propagateComposedEvents: true
                }
            }
        }
    }

    // Community tooltip - positioned absolutely above everything
    Rectangle {
        id: communityTooltip
        parent: aboutTab
        z: 1000

        property var hoveredButton: {
            if (compositorButton.hovered)
                return compositorButton;
            if (matrixButton.visible && matrixButton.hovered)
                return matrixButton;
            if (ircButton.visible && ircButton.hovered)
                return ircButton;
            if (dmsDiscordButton.hovered)
                return dmsDiscordButton;
            if (compositorDiscordButton.visible && compositorDiscordButton.hovered)
                return compositorDiscordButton;
            if (redditButton.visible && redditButton.hovered)
                return redditButton;
            return null;
        }

        property string tooltipText: hoveredButton ? hoveredButton.tooltipText : ""

        visible: hoveredButton !== null && tooltipText !== ""
        width: tooltipLabel.implicitWidth + 24
        height: tooltipLabel.implicitHeight + 12

        color: Theme.surfaceContainer
        radius: Theme.cornerRadius
        border.width: 0
        border.color: Theme.outlineMedium

        x: hoveredButton ? hoveredButton.mapToItem(aboutTab, hoveredButton.width / 2, 0).x - width / 2 : 0
        y: hoveredButton ? communityIcons.mapToItem(aboutTab, 0, 0).y - height - 8 : 0

        ElevationShadow {
            anchors.fill: parent
            z: -1
            level: Theme.elevationLevel1
            fallbackOffset: 1
            targetRadius: communityTooltip.radius
            targetColor: communityTooltip.color
            borderColor: communityTooltip.border.color
            borderWidth: communityTooltip.border.width
            shadowOpacity: Theme.elevationLevel1 && Theme.elevationLevel1.alpha !== undefined ? Theme.elevationLevel1.alpha : 0.2
            shadowEnabled: Theme.elevationEnabled
        }

        StyledText {
            id: tooltipLabel
            anchors.centerIn: parent
            text: communityTooltip.tooltipText
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceText
        }
    }
}

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

ListView {
    id: conversationView

    // Properties for state tracking - simplified
    property bool responseInProgress: false // Track if a response is being generated
    property bool navigable: true // Make focusable for keyboard navigation
    property bool isActiveItem: false // For focus management
    property bool scrollModeActive: false // Track if scroll mode is active
    // Expose scrolling animation for FocusManager
    property alias scrollAnimation: smoothScrollAnimation

    // Signal to notify when scroll mode changes
    signal scrollModeChanged(bool active)

    // Update function for external callers
    function setResponseInProgress(inProgress) {
        responseInProgress = inProgress;
        if (inProgress) {
            // Force scroll to bottom when response starts
            positionViewAtEnd();
        }
    }

    // Force scroll to bottom immediately
    function scrollToBottom() {
        positionViewAtEnd();
    }

    // Method to update the model and scroll to bottom conditionally
    function updateModel(newModel) {
        // Record current position state
        var wasAtEnd = atYEnd;
        // Update model
        model = newModel;
        // Position view based on context
        if (responseInProgress || wasAtEnd) {
            positionViewAtEnd();
        }
    }

    objectName: "conversationView"
    focus: isActiveItem
    clip: true
    spacing: ThemeManager.spacingSmall
    interactive: true
    boundsBehavior: Flickable.StopAtBounds

    // Use ListView's built-in positioning features
    onContentHeightChanged: {
        if (responseInProgress || atYEnd) {
            positionViewAtEnd();
        }
    }

    // Automatically scroll to the end when model changes during a response
    onModelChanged: {
        if (responseInProgress || atYEnd || count === 0) {
            positionViewAtEnd();
        }
    }

    // Simplified scroll mode handling
    onScrollModeActiveChanged: {
        activeScrollModeInstructions.visible = scrollModeActive;
    }

    // Add keyboard handling for scroll mode
    Keys.onPressed: function (event) {
        if (scrollModeActive) {
            var scrollAmount = 50; // Pixels to scroll per key press

            if (event.key === Qt.Key_Down) {
                // Simplified scrolling down with bounds protection
                contentY = Math.min(contentY + scrollAmount, Math.max(0, contentHeight - height));
                event.accepted = true;
            } else if (event.key === Qt.Key_Up) {
                // Simplified scrolling up with bounds protection
                contentY = Math.max(contentY - scrollAmount, 0);
                event.accepted = true;
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                // Exit scroll mode
                FocusManager.exitScrollMode();
                scrollModeChanged(false);
                event.accepted = true;
            }
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            // Enter scroll mode if there's content to scroll
            if (contentHeight > height) {
                FocusManager.enterScrollMode();
                scrollModeChanged(true);
                event.accepted = true;
            }
        }
    }

    // Animation with zero duration for compatibility with code expecting the animation
    NumberAnimation {
        id: smoothScrollAnimation
        target: conversationView
        property: "contentY"
        duration: 0 // No animation for e-ink
        easing.type: Easing.Linear
    }

    // Visual instruction when in focus but not in scroll mode
    Rectangle {
        id: scrollModeInstructions
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: ThemeManager.spacingNormal
        height: scrollModeText.height + ThemeManager.spacingLarge
        width: scrollModeText.width + ThemeManager.spacingSmall * 3
        color: ThemeManager.textColor
        border.width: ThemeManager.borderWidth
        border.color: ThemeManager.textColor
        radius: ThemeManager.borderRadius
        visible: isActiveItem && !scrollModeActive && conversationView.contentHeight > conversationView.height
        z: 2

        Text {
            id: scrollModeText
            anchors.centerIn: parent
            text: "Press Enter to enable scroll mode"
            color: ThemeManager.backgroundColor
            font: FontManager.small
        }
    }

    // Visual instruction when in scroll mode
    Rectangle {
        id: activeScrollModeInstructions
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: ThemeManager.spacingNormal
        height: activeScrollModeText.height + ThemeManager.spacingLarge
        width: activeScrollModeText.width + ThemeManager.spacingSmall * 3
        color: ThemeManager.textColor
        border.width: ThemeManager.borderWidth
        border.color: ThemeManager.textColor
        radius: ThemeManager.borderRadius
        visible: scrollModeActive
        z: 2

        Text {
            id: activeScrollModeText
            anchors.centerIn: parent
            text: "Use ↑/↓ to scroll, Enter to exit"
            color: ThemeManager.backgroundColor
            font: FontManager.small
        }
    }

    // Delegate for message items
    delegate: MessageItem {
        width: ListView.view.width
        messageText: typeof modelData === "string" ? modelData : ""
        isLastMessage: index === conversationView.count - 1
        isResponding: conversationView.responseInProgress && index === conversationView.count - 1
    }
}

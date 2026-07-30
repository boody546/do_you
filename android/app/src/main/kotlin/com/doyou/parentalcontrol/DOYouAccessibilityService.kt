package com.doyou.parentalcontrol

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.util.Log

class DOYouAccessibilityService : AccessibilityService() {

    companion object {
        private const val TAG = "DOYouAccessibility"
        var lastCapturedUrl: String? = null
            private set
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return

        val packageName = event.packageName?.toString() ?: return
        if (isBrowserPackage(packageName)) {
            val rootNode = rootInActiveWindow ?: return
            captureUrlFromNode(rootNode, packageName)
        }
    }

    private fun isBrowserPackage(pkg: String): Boolean {
        return pkg.contains("chrome") ||
                pkg.contains("browser") ||
                pkg.contains("firefox") ||
                pkg.contains("opera") ||
                pkg.contains("edge")
    }

    private fun captureUrlFromNode(node: AccessibilityNodeInfo, pkg: String) {
        val count = node.childCount
        for (i in 0 until count) {
            val child = node.getChild(i) ?: continue
            
            // Check if node is URL address bar
            val text = child.text?.toString() ?: ""
            if (text.contains(".") && (text.startsWith("http") || text.startsWith("www") || text.contains(".com") || text.contains(".org") || text.contains(".net"))) {
                if (text != lastCapturedUrl) {
                    lastCapturedUrl = text
                    Log.d(TAG, "Captured Browser Activity URL: $text from package: $pkg")
                }
            }
            captureUrlFromNode(child, pkg)
        }
    }

    override fun onInterrupt() {
        Log.d(TAG, "DOyou Accessibility Service Interrupted")
    }
}

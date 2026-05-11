package com.iiordanov.bVNC.protocol

import android.app.Activity
import android.content.Context
import android.content.Intent
import com.iiordanov.bVNC.Utils
import com.undatech.opaque.Connection
import com.undatech.opaque.Viewable
import com.undatech.remoteClientUi.R

class RemoteConnectionFactory(
    val context: Context,
    val connection: Connection?,
    val viewable: Viewable,
    private val hideKeyboardAndExtraKeys: Runnable,
) {
    // Package-based detection (may fail for embedded app)
    private var isVnc = Utils.isVnc(context)
    private var isRdp = Utils.isRdp(context)
    private var isSpiceByPackage = Utils.isSpice(context)
    private var isOpaque = Utils.isOpaque(context)

    // Connection type string-based detection (more reliable for embedded)
    private var isSpiceByConnectionType =
        connection?.connectionTypeString == context.resources.getString(R.string.connection_type_spice)

    // Check if this is a SPICE URI launch (spice://...) or spice+ URL (spice+https://...)
    private var isSpiceByUri: Boolean = false
    // Check if this is a PVE spice+ URL (spice+https://...)
    private var isPveSpiceUrl: Boolean = false
    init {
        if (context is Activity) {
            val intent: Intent? = context.intent
            val scheme = intent?.data?.scheme
            isSpiceByUri = scheme == "spice"
            // Check for PVE spice+ URLs: spice+https or spice+http
            isPveSpiceUrl = scheme == "spice+https" || scheme == "spice+http"
        }
    }

    // Combined SPICE detection - true if any method detects SPICE (but not PVE URLs which need special handling)
    private var isSpice = isSpiceByPackage || isSpiceByConnectionType || isSpiceByUri

    private var isOvirt =
        connection?.connectionTypeString == context.resources.getString(R.string.connection_type_ovirt)

    private var isProxmox =
        connection?.connectionTypeString == context.resources.getString(R.string.connection_type_pve)

    fun build(): RemoteConnection {
        val remoteConnection: RemoteConnection
        // PVE spice+ URLs need special handling via RemoteProxmoxConnection
        if (isPveSpiceUrl) {
            remoteConnection = RemoteProxmoxConnection(context, connection, viewable, hideKeyboardAndExtraKeys)
        } else if (isSpice) {
            remoteConnection =
                RemoteSpiceConnection(context, connection, viewable, hideKeyboardAndExtraKeys)
        } else if (isRdp) {
            // RDP requires freeRDPCore which cannot be compiled with modern toolchain
            // Redirect to SPICE connection as fallback
            remoteConnection =
                RemoteSpiceConnection(context, connection, viewable, hideKeyboardAndExtraKeys)
        } else if (isVnc) {
            remoteConnection = RemoteVncConnection(context, connection, viewable, hideKeyboardAndExtraKeys)
        } else if (isOpaque) {
            remoteConnection = if (isOvirt) {
                RemoteOvirtConnection(context, connection, viewable, hideKeyboardAndExtraKeys)
            } else if (isProxmox) {
                RemoteProxmoxConnection(context, connection, viewable, hideKeyboardAndExtraKeys)
            } else {
                RemoteSpiceConnection(context, connection, viewable, hideKeyboardAndExtraKeys)
            }
        } else {
            // Default to SPICE for embedded VV viewer
            remoteConnection =
                RemoteSpiceConnection(context, connection, viewable, hideKeyboardAndExtraKeys)
        }
        return remoteConnection
    }
}

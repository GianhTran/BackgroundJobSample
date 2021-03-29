package com.sogia.backgroundsample.feature.home

import android.Manifest
import android.app.Activity
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.net.Uri
import android.os.Build
import androidx.appcompat.app.AppCompatActivity
import android.os.Bundle
import android.os.IBinder
import android.provider.Settings
import androidx.appcompat.app.AlertDialog
import com.karumi.dexter.Dexter
import com.karumi.dexter.MultiplePermissionsReport
import com.karumi.dexter.PermissionToken
import com.karumi.dexter.listener.PermissionRequest
import com.karumi.dexter.listener.multi.MultiplePermissionsListener
import com.sogia.backgroundsample.R
import com.sogia.backgroundsample.feature.service.userlocationtrackingservice.UserLocationTrackingService

class MainActivity : AppCompatActivity() {
    companion object {
        const val REQUEST_CODE_OPEN_SETTING = 101
    }

    // Tracks the isServiceBoundState state of the service.
    private var isServiceBoundState = false

    // A reference to the service used to get location updates.
    private var service: UserLocationTrackingService? = null

    private var requestPermissionDialog: AlertDialog? = null

    // Monitors the state of the connection to the service.
    private val serviceConnection = object : ServiceConnection {
        override fun onServiceConnected(name: ComponentName, iBinder: IBinder) {
            val binder = iBinder as UserLocationTrackingService.LocalBinder
            service = binder.service
            isServiceBoundState = true

            requestServiceUpdates()
        }

        override fun onServiceDisconnected(name: ComponentName) {
            service = null
            isServiceBoundState = false
        }
    }

    fun stopService() {
        service?.stopService()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
    }

    override fun onStart() {
        super.onStart()
        // Bind to the service. If the service is in foreground mode, this signals to the service
        // that since this activity is in the foreground, the service can exit foreground mode.
        bindService(
            Intent(this, UserLocationTrackingService::class.java),
            serviceConnection,
            Context.BIND_AUTO_CREATE
        )
    }

    override fun onStop() {
        if (isServiceBoundState) {
            // Unbind from the service. This signals to the service that this activity is no longer
            // in the foreground, and the service can respond by promoting itself to a foreground
            // service.
            unbindService(serviceConnection)
            isServiceBoundState = false
        }
        super.onStop()
    }

    private fun requestServiceUpdates() {
        val permissions = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) listOf(
            Manifest.permission.ACCESS_COARSE_LOCATION,
            Manifest.permission.ACCESS_FINE_LOCATION
        )
        else listOf(
            Manifest.permission.ACCESS_COARSE_LOCATION, Manifest.permission.ACCESS_FINE_LOCATION
        )

        Dexter.withActivity(this@MainActivity).withPermissions(permissions)
            .withListener(object : MultiplePermissionsListener {
                override fun onPermissionsChecked(report: MultiplePermissionsReport?) {
                    if (report?.areAllPermissionsGranted() == true) {
                        try {
                            service?.requestLocationUpdates()
                        } catch (ex: IllegalStateException) {
                            // not allow to start service
                        }
                    } else {
                        showSettingsDialog(this@MainActivity)
                    }

                    if (report?.isAnyPermissionPermanentlyDenied == true) {
                        showSettingsDialog(this@MainActivity)
                    }
                }

                override fun onPermissionRationaleShouldBeShown(
                    permissions: MutableList<PermissionRequest>?, token: PermissionToken?
                ) {
                    token?.continuePermissionRequest()
                }
            }).check()
    }

    private fun showSettingsDialog(context: Activity) {
        if (requestPermissionDialog == null) {
            val builder = AlertDialog.Builder(context)
            builder.setTitle(context.getString(R.string.dialog_permission_title))
            builder.setMessage(context.getString(R.string.dialog_permission_message))
            builder.setCancelable(false)
            builder.setPositiveButton(context.getString(R.string.go_to_settings)) { dialog, _ ->
                dialog.cancel()
                openSettings(context)
                requestPermissionDialog = null
            }
            requestPermissionDialog = builder.show()
        }
    }

    private fun openSettings(context: Activity) {
        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
        val uri = Uri.fromParts("package", context.packageName, null)
        intent.data = uri
        context.startActivityForResult(intent, REQUEST_CODE_OPEN_SETTING)
    }
}
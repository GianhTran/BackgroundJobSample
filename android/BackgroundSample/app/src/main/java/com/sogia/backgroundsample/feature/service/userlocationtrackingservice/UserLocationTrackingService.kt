package com.sogia.backgroundsample.feature.service.userlocationtrackingservice

import android.app.*
import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.location.Location
import android.os.*
import android.util.Log
import android.widget.Toast
import androidx.annotation.RequiresApi
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationCompat.PRIORITY_MAX
import com.google.android.gms.location.*
import com.sogia.backgroundsample.BuildConfig
import java.lang.ref.WeakReference
import java.util.*
import com.sogia.backgroundsample.R

class UserLocationTrackingService : Service() {
    companion object {
        /**
         * The name of the channel for notifications.
         */
        private const val CHANNEL_ID = "background_sample"

        /**
         * The identifier for the notification displayed for the foreground service.
         */
        private const val NOTIFICATION_ID = 11111111

        /**
         * The desired interval for location updates. Inexact. Updates may be more or less frequent.
         */
        private const val UPDATE_INTERVAL_IN_MILLISECONDS = 15000L // 15s

        /**
         * The fastest rate for active location updates. Updates will never be more frequent
         * than this value.
         */
        private const val FASTEST_UPDATE_INTERVAL_IN_MILLISECONDS =
            UPDATE_INTERVAL_IN_MILLISECONDS / 2

        const val TAG = "UserLocationTrackingService"
    }

    private var notificationManager: NotificationManager? = null

    private var isSelfDestroy = false

    /**
     * Provides access to the Fused Location Provider API.
     */
    private lateinit var fusedLocationClient: FusedLocationProviderClient

    /**
     * Callback for changes in location.
     */
    private lateinit var locationCallback: LocationCallback

    /**
     * Used to check whether the isServiceBoundState activity has really gone away and not unbound as part of an
     * orientation change. We create a foreground service notification only if the former takes
     * place.
     */
    private var changingConfiguration = false

    private val binder = LocalBinder()

    /**
     * Contains parameters used by [com.google.android.gms.location.FusedLocationProviderApi].
     */
    private var locationRequest: LocationRequest? = null

    /**
     * The current location.
     */
    private var location: Location? = null

    private lateinit var commandHandler: CommandHandler

    enum class Command(val index: Int, val string: String) {
        INVALID(-1, "INVALID"), ACTION_START(0, "START"), ACTION_SYNC_GPS(
            1, "SYNC_GPS"
        );

        companion object {
            private val types = values().associateBy { it.index }
            fun findByValue(value: Int) = types[value]
        }
    }

    fun runService(cmd: Command?) {
        when (cmd) {
            Command.ACTION_SYNC_GPS -> {
                commandHandler.scheduleNextSyncGPS(BuildConfig.TRACKING_LOCATION_INTERVAL_IN_MILLIS)

                onSyncLocation()
            }

            else -> Log.i(
                UserLocationTrackingService::class.java.simpleName,
                "Invalid / ignored command: $cmd. Nothing to do"
            )
        }
    }

    private fun onSyncLocation() {
        location?.let {
            showMessage("onSyncLocation lat=" + it.latitude + " lng=" + it.longitude)
        }
    }

    override fun onCreate() {
        super.onCreate()
        fusedLocationClient = LocationServices.getFusedLocationProviderClient(this)

        commandHandler = CommandHandler(WeakReference(this))

        locationCallback = object : LocationCallback() {
            override fun onLocationResult(locationResult: LocationResult?) {
                super.onLocationResult(locationResult)
                locationResult?.lastLocation?.let {
                    onNewLocation(it)
                }
            }
        }

        createLocationRequest()

        setupCycles()
    }

    private fun setupCycles() {
        commandHandler.scheduleNextSyncGPS(0)
    }

    private fun showMessage(message: String) {
        Handler(Looper.getMainLooper()).post {
            Toast.makeText(this@UserLocationTrackingService, message, Toast.LENGTH_LONG).show()
        }
    }

    fun stopService() {
        isSelfDestroy = true
        removeLocationUpdates()
        stopSelf()
    }

    private fun onNewLocation(location: Location) {
        val minGPSAccuracyInMeter = BuildConfig.MIN_GPS_ACCURACY_IN_METER

        if (location.hasAccuracy()) {
            if (location.accuracy <= minGPSAccuracyInMeter.toFloat()) {
                this.location = location
                Log.e(TAG, "Location valid with accuracy = " + location.accuracy)
            } else {
                Log.e(TAG, "Location IN-valid with accuracy = " + location.accuracy)
            }
        } else {
            Log.e(TAG, "Location has No accuracy = " + location.accuracy)

            this.location = location
        }
    }

    /**
     * Removes location updates. Note that in this sample we merely log the
     * [SecurityException].
     */
    private fun removeLocationUpdates() {
        try {
            fusedLocationClient.removeLocationUpdates(locationCallback)
        } catch (unlikely: SecurityException) {
        }
    }

    fun requestLocationUpdates() {
        startService(Intent(applicationContext, UserLocationTrackingService::class.java))

        try {
            locationRequest?.let {
                fusedLocationClient.requestLocationUpdates(
                    it, locationCallback, Looper.myLooper()
                )
            }
        } catch (unlikely: SecurityException) {
            unlikely.printStackTrace()
        }
    }

    /**
     * Sets the location request parameters.
     */
    private fun createLocationRequest() {
        locationRequest = LocationRequest()
        locationRequest?.interval = UPDATE_INTERVAL_IN_MILLISECONDS
        locationRequest?.fastestInterval = FASTEST_UPDATE_INTERVAL_IN_MILLISECONDS
        locationRequest?.priority = LocationRequest.PRIORITY_HIGH_ACCURACY
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // Tells the system to not try to recreate the service after it has been killed.
        return START_NOT_STICKY
    }

    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        changingConfiguration = true
    }

    override fun onBind(intent: Intent): IBinder? {
        // Called when a client comes to the foreground
        // and binds with this service. The service should cease to be a foreground service
        // when that happens.
        stopForeground(true)
        changingConfiguration = false
        return binder
    }

    override fun onRebind(intent: Intent) {
        // Called when a client returns to the foreground
        // and binds once again with this service. The service should cease to be a foreground
        // service when that happens.
        stopForeground(true)
        changingConfiguration = false
        super.onRebind(intent)
    }

    override fun onUnbind(intent: Intent): Boolean {
        // Called when the last client unbinds from this
        // service. If this method is called due to a configuration change in MainActivity, we
        // do nothing. Otherwise, we make this service a foreground service.
        if (!changingConfiguration) {
            startForeground(NOTIFICATION_ID, getForegroundNotification())
        }
        return true // Ensures onRebind() is called when a client re-binds.
    }

    override fun onDestroy() {
        commandHandler.removeCallbacksAndMessages(null)

        super.onDestroy()
    }

    /**
     * Class used for the client Binder.  Since this service runs in the same process as its
     * clients, we don't need to deal with IPC.
     */
    inner class LocalBinder : Binder() {
        internal val service: UserLocationTrackingService
            get() = this@UserLocationTrackingService
    }

    /**
     * Returns true if this is a foreground service.
     *
     * @param context The [Context].
     */
    private fun serviceIsRunningInForeground(context: Context): Boolean {
        val manager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        for (service in manager.getRunningServices(Integer.MAX_VALUE)) {
            if (javaClass.name == service.service.className) {
                if (service.foreground) {
                    return true
                }
            }
        }
        return false
    }

    /**
     * Returns the [NotificationCompat] used as part of the foreground service.
     */
    private fun getForegroundNotification(): Notification {
        notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        val channelId = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            createNotificationChannel(CHANNEL_ID, "My Background Service")
        } else {
            // If earlier version channel ID is not used
            // https://developer.android.com/reference/android/support/v4/app/NotificationCompat.Builder.html#NotificationCompat.Builder(android.content.Context)
            ""
        }

        val builder = NotificationCompat.Builder(this, channelId).setSmallIcon(R.mipmap.ic_launcher)
            .setPriority(PRIORITY_MAX).setContentText(getString(R.string.app_name))

        return builder.build()
    }

    @RequiresApi(Build.VERSION_CODES.O)
    private fun createNotificationChannel(channelId: String, channelName: String): String {
        val chan = NotificationChannel(
            channelId, channelName, NotificationManager.IMPORTANCE_NONE
        )
        val service = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        service.createNotificationChannel(chan)
        return channelId
    }
}
package com.sogia.backgroundsample.feature.service.userlocationtrackingservice

import android.os.Handler
import android.os.Message
import java.lang.ref.WeakReference

class CommandHandler(private val service: WeakReference<UserLocationTrackingService>) : Handler() {
    override fun handleMessage(msg: Message) {
        super.handleMessage(msg)
        msg.let {
            val cmd = msg.what
            service.get()?.runService(UserLocationTrackingService.Command.findByValue(cmd))
        }
    }

    private fun sendCommandMsg(cmd: UserLocationTrackingService.Command, delay: Long) {
        val msg = Message.obtain(this, cmd.index)
        sendMessageDelayed(msg, delay)
    }

    fun sendCommandMsg(cmd: UserLocationTrackingService.Command) {
        val msg = obtainMessage(cmd.index)
        msg.arg1 = cmd.index
        sendMessage(msg)
    }

    fun scheduleNextSyncGPS(timeInMillis: Long) {
        cancelNextSyncGPS()
        sendCommandMsg(UserLocationTrackingService.Command.ACTION_SYNC_GPS, timeInMillis)
    }

    private fun cancelNextSyncGPS() {
        removeMessages(UserLocationTrackingService.Command.ACTION_SYNC_GPS.index)
    }
}

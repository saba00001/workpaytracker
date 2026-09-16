package com.example.workpaytracker

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import java.util.Calendar

/**
 * Receives YES/NO broadcasts from WorkConfirmActivity and persists the work day
 * directly via SharedPreferences — no Flutter engine needed.
 */
class WorkConfirmReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val worked = when (intent.action) {
            WorkConfirmActivity.ACTION_YES -> true
            WorkConfirmActivity.ACTION_NO -> false
            else -> return
        }

        val cal = Calendar.getInstance()
        val year = cal.get(Calendar.YEAR)
        val month = cal.get(Calendar.MONTH) + 1
        val day = cal.get(Calendar.DAY_OF_MONTH)

        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

        // Guard key — prevent duplicate recording for same day + same status
        val guardKey = "flutter.notif_recorded_${year}_${month}_${day}"
        val workedKey = "flutter.notif_worked_${year}_${month}_${day}"

        val alreadyRecorded = prefs.getBoolean(guardKey, false)
        if (alreadyRecorded) {
            val prevWorked = prefs.getBoolean(workedKey, !worked)
            if (prevWorked == worked) return // exact duplicate
        }

        // Write work day into Flutter SharedPreferences
        // The WorkDataService reads from "flutter.work_days_v2" as a JSON array
        val workDaysKey = "flutter.work_days_v2"
        val existing = prefs.getString(workDaysKey, "[]") ?: "[]"

        val dateStr = String.format("%04d-%02d-%02dT00:00:00.000", year, month, day)
        val newEntry = """{"date":"$dateStr","worked":$worked,"wageEarned":${if (worked) getDailyWage(prefs) else 0.0}}"""

        val updated = updateWorkDays(existing, dateStr, newEntry)
        prefs.edit()
            .putString(workDaysKey, updated)
            .putBoolean(guardKey, true)
            .putBoolean(workedKey, worked)
            .apply()

        // Also update the current monthly period earned amount
        updateMonthlyPeriod(prefs, year, month, worked, getDailyWage(prefs))
    }

    private fun getDailyWage(prefs: SharedPreferences): Double {
        // Try v2 settings key first, then legacy
        val settingsJson = prefs.getString("flutter.app_settings_v2", null)
            ?: prefs.getString("flutter.app_settings", null)
        if (settingsJson != null) {
            try {
                val match = Regex(""""dailyWage"\s*:\s*([\d.]+)""").find(settingsJson)
                if (match != null) return match.groupValues[1].toDouble()
            } catch (_: Exception) {}
        }
        return 80.0
    }

    private fun updateWorkDays(existing: String, dateStr: String, newEntry: String): String {
        return try {
            // Remove existing entry for this date if present
            val cleaned = existing.trim().removeSurrounding("[", "]")
            val entries = if (cleaned.isBlank()) mutableListOf()
            else splitJsonArray(cleaned).toMutableList()

            // Remove any entry with matching date
            val filtered = entries.filter { !it.contains(dateStr) }
            val result = (filtered + newEntry).joinToString(",")
            "[$result]"
        } catch (_: Exception) {
            // Fallback: just append
            if (existing.trim() == "[]") "[$newEntry]"
            else existing.trimEnd(']') + ",$newEntry]"
        }
    }

    private fun splitJsonArray(content: String): List<String> {
        val result = mutableListOf<String>()
        var depth = 0
        var start = 0
        for (i in content.indices) {
            when (content[i]) {
                '{' -> depth++
                '}' -> {
                    depth--
                    if (depth == 0) {
                        result.add(content.substring(start, i + 1).trim())
                        start = i + 2 // skip comma
                    }
                }
            }
        }
        return result
    }

    private fun updateMonthlyPeriod(
        prefs: SharedPreferences,
        year: Int,
        month: Int,
        worked: Boolean,
        wage: Double
    ) {
        try {
            val periodKey = "flutter.monthly_periods_v2"
            val periodId = String.format("%04d-%02d", year, month)
            val existing = prefs.getString(periodKey, "[]") ?: "[]"

            // Recalculate worked days from work_days_v2
            val workDaysJson = prefs.getString("flutter.work_days_v2", "[]") ?: "[]"
            val workedDays = countWorkedDaysInMonth(workDaysJson, year, month)
            val totalEarned = workedDays * wage

            val updated = updatePeriodEarnings(existing, periodId, workedDays, totalEarned, wage)
            prefs.edit().putString(periodKey, updated).apply()
        } catch (_: Exception) {}
    }

    private fun countWorkedDaysInMonth(workDaysJson: String, year: Int, month: Int): Int {
        val prefix = String.format("%04d-%02d", year, month)
        val workedPattern = Regex(""""date"\s*:\s*"($prefix[^"]+)"\s*,\s*"worked"\s*:\s*true""")
        return workedPattern.findAll(workDaysJson).count()
    }

    private fun updatePeriodEarnings(
        existing: String,
        periodId: String,
        workedDays: Int,
        totalEarned: Double,
        wage: Double
    ): String {
        return try {
            val cleaned = existing.trim().removeSurrounding("[", "]")
            val entries = if (cleaned.isBlank()) mutableListOf()
            else splitJsonArray(cleaned).toMutableList()

            val idx = entries.indexOfFirst { it.contains(""""id":"$periodId"""") }
            if (idx >= 0) {
                // Update existing period's workedDays and totalEarned
                var entry = entries[idx]
                entry = entry.replace(Regex(""""workedDays"\s*:\s*\d+"""), """"workedDays":$workedDays""")
                entry = entry.replace(Regex(""""totalEarned"\s*:\s*[\d.]+"""), """"totalEarned":$totalEarned""")
                entries[idx] = entry
            }
            // If period not found, don't create it here — let Flutter handle period creation
            "[${entries.joinToString(",")}]"
        } catch (_: Exception) {
            existing
        }
    }
}

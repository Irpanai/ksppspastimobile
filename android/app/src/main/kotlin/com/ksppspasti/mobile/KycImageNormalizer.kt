package com.ksppspasti.mobile

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.media.ExifInterface
import java.io.File
import java.io.FileOutputStream

/**
 * Normalisasi hasil tangkapan kamera KYC agar orientasi piksel tegak lurus
 * (tanpa bergantung pada tag EXIF), opsional mencerminkan horizontal
 * agar foto selfie kamera depan selaras dengan pratinjau cermin,
 * serta opsional memotong (crop) KTP ke mode landscape (rasio ~1.585 / 4:3 s.d 16:9).
 */
object KycImageNormalizer {
    private const val MAX_OUTPUT_DIMENSION = 2560
    private const val JPEG_QUALITY = 92

    fun normalizeCapturedPhoto(
        cacheDir: File,
        sourcePath: String,
        mirrorHorizontal: Boolean,
        cropToKtpLandscape: Boolean = false,
        rotateDegrees: Int = 0,
        targetAspectRatio: Double = 1.585,
    ): String {
        val sourceFile = File(sourcePath)
        if (!sourceFile.exists() || !sourceFile.isFile) {
            return sourcePath
        }

        val exifOrientation = try {
            ExifInterface(sourcePath).getAttributeInt(
                ExifInterface.TAG_ORIENTATION,
                ExifInterface.ORIENTATION_NORMAL,
            )
        } catch (_: Exception) {
            ExifInterface.ORIENTATION_NORMAL
        }

        val needsExifTransform =
            exifOrientation != ExifInterface.ORIENTATION_NORMAL &&
                exifOrientation != ExifInterface.ORIENTATION_UNDEFINED

        if (!mirrorHorizontal && !needsExifTransform && !cropToKtpLandscape && rotateDegrees == 0) {
            return sourcePath
        }

        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(sourcePath, bounds)
        if (bounds.outWidth <= 0 || bounds.outHeight <= 0) {
            return sourcePath
        }

        val decodeOptions = BitmapFactory.Options().apply {
            inSampleSize = calculateInSampleSize(
                bounds.outWidth,
                bounds.outHeight,
                MAX_OUTPUT_DIMENSION,
            )
        }

        val decoded = BitmapFactory.decodeFile(sourcePath, decodeOptions) ?: return sourcePath
        var transformed: Bitmap? = null
        var cropped: Bitmap? = null
        return try {
            val matrix = buildOrientationAndMirrorMatrix(exifOrientation, mirrorHorizontal, rotateDegrees)
            transformed = if (!matrix.isIdentity) {
                Bitmap.createBitmap(
                    decoded,
                    0,
                    0,
                    decoded.width,
                    decoded.height,
                    matrix,
                    true,
                )
            } else {
                decoded
            }

            val finalBitmap = if (cropToKtpLandscape) {
                val tw = transformed.width
                val th = transformed.height
                val ratio = if (targetAspectRatio in 0.5..3.0) targetAspectRatio.toFloat() else 1.585f

                if (th > tw) {
                    // Kamera HP mode Portrait (vertikal): potong area horizontal tengah menjadi Landscape
                    val cropW = tw
                    val desiredH = (cropW / ratio).toInt()
                    val cropH = minOf(th, desiredH)

                    // Posisi vertikal 48% dari tinggi frame sesuai wireframe card di UI
                    val centerY = (th * 0.48f).toInt()
                    val startY = (centerY - cropH / 2).coerceIn(0, th - cropH)
                    val startX = 0

                    cropped = Bitmap.createBitmap(transformed, startX, startY, cropW, cropH)
                    cropped
                } else {
                    // Kamera HP mode Landscape (horizontal):
                    // Sesuai wireframe ~0.72 tinggi layar di UI, potong area tengah kartu KTP
                    val cropH = (th * 0.76f).toInt()
                    val desiredW = (cropH * ratio).toInt()
                    val cropW = minOf(tw, desiredW)

                    val startX = ((tw - cropW) / 2).coerceIn(0, tw - cropW)
                    val startY = ((th - cropH) / 2).coerceIn(0, th - cropH)
                    cropped = Bitmap.createBitmap(transformed, startX, startY, cropW, cropH)
                    cropped
                }
            } else {
                transformed
            }

            val outputFile = File.createTempFile("KYC_NORM_", ".jpg", cacheDir)
            FileOutputStream(outputFile).use { stream ->
                finalBitmap.compress(Bitmap.CompressFormat.JPEG, JPEG_QUALITY, stream)
                stream.flush()
            }
            outputFile.absolutePath
        } catch (_: Exception) {
            sourcePath
        } finally {
            if (cropped != null && cropped !== transformed && cropped !== decoded) {
                cropped.recycle()
            }
            if (transformed != null && transformed !== decoded) {
                transformed.recycle()
            }
            decoded.recycle()
        }
    }

    internal fun buildOrientationAndMirrorMatrix(
        exifOrientation: Int,
        mirrorHorizontal: Boolean,
        rotateDegrees: Int = 0,
    ): Matrix {
        val matrix = Matrix()
        when (exifOrientation) {
            ExifInterface.ORIENTATION_FLIP_HORIZONTAL -> matrix.postScale(-1f, 1f)
            ExifInterface.ORIENTATION_ROTATE_180 -> matrix.postRotate(180f)
            ExifInterface.ORIENTATION_FLIP_VERTICAL -> matrix.postScale(1f, -1f)
            ExifInterface.ORIENTATION_TRANSPOSE -> {
                matrix.postRotate(90f)
                matrix.postScale(-1f, 1f)
            }
            ExifInterface.ORIENTATION_ROTATE_90 -> matrix.postRotate(90f)
            ExifInterface.ORIENTATION_TRANSVERSE -> {
                matrix.postRotate(270f)
                matrix.postScale(-1f, 1f)
            }
            ExifInterface.ORIENTATION_ROTATE_270 -> matrix.postRotate(270f)
        }
        // Gunakan postScale setelah rotasi EXIF agar cerminan selalu horizontal pada tampilan tegak.
        if (mirrorHorizontal) {
            matrix.postScale(-1f, 1f)
        }
        if (rotateDegrees != 0) {
            matrix.postRotate(rotateDegrees.toFloat())
        }
        return matrix
    }

    internal fun calculateInSampleSize(
        width: Int,
        height: Int,
        maxDimension: Int,
    ): Int {
        var sampleSize = 1
        var currentMax = maxOf(width, height)
        while (currentMax / 2 >= maxDimension) {
            sampleSize *= 2
            currentMax /= 2
        }
        return sampleSize
    }
}


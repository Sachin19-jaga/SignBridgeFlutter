package com.example.sign_bridge

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.tensorflow.lite.Interpreter
import java.io.FileInputStream
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.MappedByteBuffer
import java.nio.channels.FileChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.signbridge/tflite"
    private var interpreter: Interpreter? = null
    private val IMG_SIZE = 64

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "loadModel" -> {
                        try {
                            val model = loadModelFile()
                            interpreter = Interpreter(model)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("LOAD_ERROR", e.message, null)
                        }
                    }
                    "runInference" -> {
                        try {
                            val imagePath = call.argument<String>("imagePath")!!
                            val scores = runInference(imagePath)
                            result.success(scores)
                        } catch (e: Exception) {
                            result.error("INFERENCE_ERROR", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun loadModelFile(): MappedByteBuffer {
        val assetFileDescriptor = assets.openFd("flutter_assets/assets/models/asl_model.tflite")
        val inputStream = FileInputStream(assetFileDescriptor.fileDescriptor)
        val fileChannel = inputStream.channel
        return fileChannel.map(
            FileChannel.MapMode.READ_ONLY,
            assetFileDescriptor.startOffset,
            assetFileDescriptor.declaredLength
        )
    }

    private fun runInference(imagePath: String): Map<String, Float> {
        val interp = interpreter ?: return emptyMap()

        // Load and resize image
        val bitmap = BitmapFactory.decodeFile(imagePath)
            ?: return emptyMap()
        val resized = Bitmap.createScaledBitmap(bitmap, IMG_SIZE, IMG_SIZE, true)

        // Prepare input buffer [1, 64, 64, 3] normalized 0-1
        val inputBuffer = ByteBuffer.allocateDirect(1 * IMG_SIZE * IMG_SIZE * 3 * 4)
        inputBuffer.order(ByteOrder.nativeOrder())

        for (y in 0 until IMG_SIZE) {
            for (x in 0 until IMG_SIZE) {
                val pixel = resized.getPixel(x, y)
                inputBuffer.putFloat(((pixel shr 16) and 0xFF) / 255.0f) // R
                inputBuffer.putFloat(((pixel shr 8)  and 0xFF) / 255.0f) // G
                inputBuffer.putFloat((pixel           and 0xFF) / 255.0f) // B
            }
        }

        // Get output size from interpreter
        val outputShape = interp.getOutputTensor(0).shape()
        val numClasses = outputShape[1]
        val outputBuffer = Array(1) { FloatArray(numClasses) }

        interp.run(inputBuffer, outputBuffer)

        // Return as map of index -> score
        val scores = mutableMapOf<String, Float>()
        for (i in 0 until numClasses) {
            scores[i.toString()] = outputBuffer[0][i]
        }
        return scores
    }
}

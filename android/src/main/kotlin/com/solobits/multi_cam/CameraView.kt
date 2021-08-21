package com.solobits.multi_cam


import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.graphics.Color
import android.view.View
import android.view.ViewGroup
import android.widget.RelativeLayout
import androidx.camera.camera2.Camera2Config
import androidx.camera.core.CameraSelector
import androidx.camera.core.CameraXConfig
import androidx.camera.core.Preview
import androidx.camera.core.impl.utils.ContextUtil
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.LifecycleRegistry
import com.google.common.util.concurrent.ListenableFuture
import io.flutter.plugin.platform.PlatformView



internal class CameraView(context: Context, id: Int, creationParams: Map<String?, Any?>?) : PlatformView, LifecycleOwner {

//    private val backView: RelativeLayout
//    private val frontView: RelativeLayout


    //CAMERAX
    private val previewView: PreviewView = PreviewView(context)
    private val lifecycleRegistry: LifecycleRegistry = LifecycleRegistry(this)
    private var cameraProviderFuture : ListenableFuture<ProcessCameraProvider> =
        ProcessCameraProvider.getInstance(context)


    override fun getView(): View {
        return previewView
    }

    override fun dispose() {}

    //CameraX
    override fun getLifecycle(): Lifecycle {
        return lifecycleRegistry
    }

    init {

        //CAMERAX
        lifecycleRegistry.markState(Lifecycle.State.CREATED)
        cameraProviderFuture.addListener(Runnable {
            val cameraProvider = cameraProviderFuture.get()
            bindPreview(cameraProvider, context)
        }, ContextCompat.getMainExecutor(context))

        previewView.layoutParams  = ViewGroup.LayoutParams(500,700)


//        val params = RelativeLayout.LayoutParams(480, 550)
//        params.rightMargin = 5
//        params.bottomMargin = 5
//        params.addRule(RelativeLayout.ALIGN_PARENT_RIGHT)
//        params.addRule(RelativeLayout.ALIGN_PARENT_BOTTOM)
//
//        frontView = RelativeLayout(context)
//        frontView.layoutParams = params;
//
//        backView = RelativeLayout(context)
//        backView.layoutParams = RelativeLayout.LayoutParams(RelativeLayout.LayoutParams.MATCH_PARENT,RelativeLayout.LayoutParams.MATCH_PARENT)
//        backView.addView(frontView)




    }


    fun bindPreview(cameraProvider : ProcessCameraProvider, context:Context) {
        var preview : Preview = Preview.Builder()
            .build()

        var cameraSelector : CameraSelector = CameraSelector.Builder()
            .requireLensFacing(CameraSelector.LENS_FACING_FRONT)
            .build()


        preview.

        setOnPreviewOutputUpdateListener {
            val parent = viewFinder.parent as ViewGroup
            parent.removeView(viewFinder)
            viewFinder.surfaceTexture = it.surfaceTexture
            parent.addView(viewFinder, 0)
            updateTransform()
        }


        preview.setSurfaceProvider(previewView.surfaceProvider)

        cameraProvider.unbindAll()
        var camera = cameraProvider.bindToLifecycle(this as LifecycleOwner, cameraSelector, preview)

    }

}
package com.taba.tabai.feature.chat.components

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.taba.tabai.core.designsystem.DS

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AttachmentSheet(
    onPhoto: () -> Unit,
    onCamera: () -> Unit,
    onFile: () -> Unit,
    onGenerateImage: () -> Unit = {},
    onGenerateVideo: () -> Unit = {},
    onDismiss: () -> Unit,
) {
    ModalBottomSheet(
        onDismissRequest = onDismiss,
        containerColor = DS.backgroundTop,
        shape = RoundedCornerShape(topStart = 20.dp, topEnd = 20.dp),
    ) {
        Column(Modifier.fillMaxWidth().padding(horizontal = 20.dp).padding(bottom = 32.dp)) {
            Text("Attach", fontWeight = FontWeight.SemiBold, fontSize = 18.sp, color = DS.textPrimary)
            Spacer(Modifier.height(16.dp))
            AttachOption(Icons.Default.Photo, "Photo Library", "Choose from gallery", onClick = { onPhoto(); onDismiss() })
            Spacer(Modifier.height(8.dp))
            AttachOption(Icons.Default.CameraAlt, "Camera", "Take a photo", onClick = { onCamera(); onDismiss() })
            Spacer(Modifier.height(8.dp))
            AttachOption(Icons.Default.AttachFile, "File", "Browse files", onClick = { onFile(); onDismiss() })
            Spacer(Modifier.height(16.dp))
            HorizontalDivider(color = DS.glassStroke)
            Spacer(Modifier.height(16.dp))
            Text("Create", fontWeight = FontWeight.SemiBold, fontSize = 18.sp, color = DS.textPrimary)
            Spacer(Modifier.height(16.dp))
            AttachOption(Icons.Default.AutoAwesome, "Generate Image", "Create an image from a text prompt", onClick = { onGenerateImage(); onDismiss() })
            Spacer(Modifier.height(8.dp))
            AttachOption(Icons.Default.Movie, "Generate Video", "Create a video from a text prompt", onClick = { onGenerateVideo(); onDismiss() })
        }
    }
}

@Composable
private fun AttachOption(icon: ImageVector, title: String, subtitle: String, onClick: () -> Unit) {
    Surface(
        modifier = Modifier.fillMaxWidth().clickable(onClick = onClick),
        shape = RoundedCornerShape(14.dp),
        color = DS.cardBackground,
    ) {
        Row(
            Modifier.padding(horizontal = 16.dp, vertical = 14.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Icon(icon, null, tint = DS.accent, modifier = Modifier.size(24.dp))
            Spacer(Modifier.width(14.dp))
            Column(Modifier.weight(1f)) {
                Text(title, fontSize = 15.sp, fontWeight = FontWeight.Medium, color = DS.textPrimary)
                Text(subtitle, fontSize = 12.sp, color = DS.textSecondary)
            }
            Icon(Icons.Default.ChevronRight, null, tint = DS.textSecondary.copy(alpha = 0.4f), modifier = Modifier.size(18.dp))
        }
    }
}

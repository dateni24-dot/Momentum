# =============================================================================
# flutter_local_notifications — preservar Gson TypeToken para deserialización
# Fix bug "Missing type parameter" en release builds con R8
# =============================================================================
-keep class com.dexterous.** { *; }
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Gson — preservar info de tipos genéricos
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses
-keep class com.google.gson.** { *; }
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken

# Preservar clases con parámetros genéricos
-keep,allowobfuscation,allowshrinking class * extends com.google.gson.reflect.TypeToken
-keep,allowobfuscation,allowshrinking interface *

# Preservar nombres de clases serializadas por flutter_local_notifications
-keep class com.dexterous.flutterlocalnotifications.models.** { *; }
-keep class com.dexterous.flutterlocalnotifications.models.NotificationDetails { *; }

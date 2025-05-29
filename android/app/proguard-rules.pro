# Keep Jackson annotations and related classes
-keepattributes *Annotation*

-keep class com.fasterxml.jackson.databind.** { *; }
-keep class com.fasterxml.jackson.core.** { *; }
-keep class com.fasterxml.jackson.annotation.** { *; }
-keep class com.fasterxml.jackson.module.kotlin.** { *; }

# Keep Java beans annotations
-keep class java.beans.** { *; }

# Keep DOM implementation class
-keep class org.w3c.dom.bootstrap.DOMImplementationRegistry { *; }

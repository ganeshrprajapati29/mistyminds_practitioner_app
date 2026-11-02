# Agora RTC — native code calls back into these classes by name.
-keep class io.agora.** { *; }
-dontwarn io.agora.**

# Firebase Messaging / local notifications keep their own rules via their AARs.

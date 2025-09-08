# Stripe specific rules
-keep class com.stripe.android.pushProvisioning.** { *; }
-dontwarn com.stripe.android.pushProvisioning.**
-keep class com.reactnativestripesdk.** { *; }
-dontwarn com.reactnativestripesdk.**
-keep class com.stripe.android.** { *; }
-dontwarn com.stripe.android.**

# General rules for missing classes
-dontwarn java.lang.invoke.StringConcatFactory
-dontwarn javax.annotation.**
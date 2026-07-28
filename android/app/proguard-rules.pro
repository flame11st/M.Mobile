# Guava references this optional annotation only as metadata. It is not
# required at runtime, but R8 needs the generated suppression to finish.
-dontwarn com.google.j2objc.annotations.ReflectionSupport

# Google Mobile Ads currently brings an older WorkManager/Room that creates
# WorkDatabase_Impl by reflection. R8 must preserve both names and constructors
# or release APKs crash before MainActivity starts.
# https://github.com/googleads/googleads-mobile-flutter/issues/1532
-keep class androidx.work.impl.WorkDatabase { *; }
-keep class androidx.work.impl.WorkDatabase_Impl { *; }

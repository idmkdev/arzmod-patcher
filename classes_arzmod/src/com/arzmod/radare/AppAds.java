package com.arzmod.radare;

import com.unity3d.ads.IUnityAdsLoadListener;
import com.unity3d.ads.IUnityAdsShowListener;
import com.unity3d.ads.IUnityAdsInitializationListener;
import com.unity3d.ads.UnityAds;
import com.unity3d.ads.metadata.MetaData;
import com.unity3d.services.banners.BannerView;
import com.unity3d.services.banners.UnityBannerSize;
import com.unity3d.services.banners.BannerErrorInfo;
import android.util.Log;
import android.content.Context;
import com.arzmod.radare.AppContext;
import android.app.Activity;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import android.view.Gravity;
import android.view.View;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;


public class AppAds {
    private static boolean initialized = false;
    private static BannerView banner;
    private static boolean rewardedShown = false;
    private static CountDownLatch rewardedLatch;

    public static void checkInitialization(boolean showBanner) {
        Activity activity = AppContext.getActivity();
        if (activity == null) {
            Log.e("arzmod-unityads-module", "Activity is null, cannot initialize ads");
            return;
        }
       
        if (initialized) {
            Log.d("arzmod-unityads-module", "Unity Ads already initialized");
            return;
        }

        Log.d("arzmod-unityads-module", "Activity: " + activity.getClass().getName());
        try {
            UnityAds.initialize(activity, "5917151", false, new IUnityAdsInitializationListener() {
                @Override
                public void onInitializationComplete() {
                    Log.d("arzmod-unityads-module", "Unity Ads initialized successfully");
                    initialized = true;
                    if (showBanner) showBanner();
                }

                @Override
                public void onInitializationFailed(UnityAds.UnityAdsInitializationError error, String message) {
                    Log.e("arzmod-unityads-module", "Unity Ads initialization failed: " + message);
                }
            });
        } catch (Exception e) {
            Log.e("arzmod-unityads-module", "Error initializing Unity Ads: " + e.getMessage());
        }
    }

    public static void showBanner() {
        Activity activity = AppContext.getActivity();
        if (activity == null) {
            Log.e("arzmod-unityads-module", "Activity is null, cannot show banner ads");
            return;
        }

        if (activity.getClass().getName().equals("com.arizona.game.GTASA")) {
            Log.d("arzmod-unityads-module", "GTASA activity, skipping banner");
            return;
        }

        if(SettingsPatch.getSettingsKeyValue(SettingsPatch.IS_DEV_HUNGRY))
        {
            Log.d("arzmod-unityads-module", "Dev hungry mode enabled, skipping banner");
            return;
        }

        if (!initialized) {
            Log.d("arzmod-unityads-module", "Unity Ads not initialized");
            return;
        }

        activity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                if (banner == null) {
                    banner = new BannerView(activity, "Banner_Android", new UnityBannerSize(320, 50));
                    banner.setListener(new BannerView.IListener() {
                        @Override
                        public void onBannerLoaded(BannerView b) {
                            Log.d("arzmod-unityads-module", "Banner loaded");
                            try {
                                FrameLayout.LayoutParams lp = new FrameLayout.LayoutParams(
                                        FrameLayout.LayoutParams.WRAP_CONTENT,
                                        FrameLayout.LayoutParams.WRAP_CONTENT
                                );
                                lp.gravity = Gravity.TOP | Gravity.CENTER_HORIZONTAL;
                                activity.addContentView(b, lp);
                            } catch (Exception e) {
                                Log.e("arzmod-unityads-module", "Attach banner failed: " + e.getMessage());
                            }
                        }

                        @Override
                        public void onBannerFailedToLoad(BannerView b, BannerErrorInfo errorInfo) {
                            Log.e("arzmod-unityads-module", "Banner load failed: " + errorInfo.errorMessage);
                        }

                        @Override
                        public void onBannerClick(BannerView b) {
                            Log.d("arzmod-unityads-module", "Banner clicked");
                        }

                        @Override
                        public void onBannerLeftApplication(BannerView b) {
                            Log.d("arzmod-unityads-module", "Banner left application");
                        }
                    });
                } else {
                    if (banner.getParent() == null) {
                        try {
                            FrameLayout.LayoutParams lp = new FrameLayout.LayoutParams(
                                    FrameLayout.LayoutParams.WRAP_CONTENT,
                                    FrameLayout.LayoutParams.WRAP_CONTENT
                            );
                            lp.gravity = Gravity.TOP | Gravity.CENTER_HORIZONTAL;
                            activity.addContentView(banner, lp);
                        } catch (Exception e) {
                            Log.e("arzmod-unityads-module", "Reattach banner failed: " + e.getMessage());
                        }
                    }
                    banner.setVisibility(View.VISIBLE);
                }

                try {
                    banner.load();
                } catch (Exception e) {
                    Log.e("arzmod-unityads-module", "Banner load() error: " + e.getMessage());
                }
            }
        });
    }

    public static void hideBanner() {
        if (banner != null) {
            try {
                banner.setVisibility(View.GONE);
                ViewGroup parent = (ViewGroup) banner.getParent();
                if (parent != null) parent.removeView(banner);
                banner = null;
            } catch (Exception e) {
                Log.e("arzmod-unityads-module", "Hide banner failed: " + e.getMessage());
            }
        }
    }

    public static boolean showRewarded() {
        Activity activity = AppContext.getActivity();
        if (activity == null) {
            Log.e("arzmod-unityads-module", "Activity is null, cannot show rewarded ad");
            return false;
        }
        
        if (!initialized) {
            Log.d("arzmod-unityads-module", "Unity Ads not initialized");
            return false;
        }

        final boolean[] adStarted = {false};
        final CountDownLatch latch = new CountDownLatch(1);

        activity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                if (!initialized) {
                    Log.e("arzmod-unityads-module", "Unity Ads not initialized, cannot show rewarded ad");
                    latch.countDown();
                    return;
                }

                String placementId = "Rewarded_Android";
                Log.d("arzmod-unityads-module", "Loading rewarded ad: " + placementId);

                UnityAds.load(placementId, new IUnityAdsLoadListener() {
                    @Override
                    public void onUnityAdsAdLoaded(String placementId) {
                        Log.d("arzmod-unityads-module", "Rewarded ad loaded, showing: " + placementId);
                        UnityAds.show(activity, placementId, new IUnityAdsShowListener() {
                            @Override
                            public void onUnityAdsShowStart(String placementId) {
                                Log.d("arzmod-unityads-module", "Rewarded ad show started: " + placementId);
                                adStarted[0] = true;
                                latch.countDown();
                            }

                            @Override
                            public void onUnityAdsShowComplete(String placementId, UnityAds.UnityAdsShowCompletionState completionState) {
                                Log.d("arzmod-unityads-module", "Rewarded ad show completed: " + placementId + ", state: " + completionState);
                            }

                            @Override
                            public void onUnityAdsShowFailure(String placementId, UnityAds.UnityAdsShowError error, String message) {
                                Log.e("arzmod-unityads-module", "Rewarded ad show failed: " + placementId + ", error: " + message);
                                latch.countDown();
                            }

                            @Override
                            public void onUnityAdsShowClick(String placementId) {
                                Log.d("arzmod-unityads-module", "Rewarded ad clicked: " + placementId);
                            }
                        });
                    }

                    @Override
                    public void onUnityAdsFailedToLoad(String placementId, UnityAds.UnityAdsLoadError error, String message) {
                        Log.e("arzmod-unityads-module", "Rewarded ad failed to load: " + placementId + ", error: " + message);
                        latch.countDown();
                    }
                });
            }
        });

        try {
            latch.await(5, TimeUnit.SECONDS);
        } catch (InterruptedException e) {
            Log.e("arzmod-unityads-module", "Rewarded ad wait interrupted: " + e.getMessage());
            Thread.currentThread().interrupt();
        }

        return adStarted[0];
    }
}
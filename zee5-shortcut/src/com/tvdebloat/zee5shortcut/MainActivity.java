package com.tvdebloat.zee5shortcut;

import android.app.Activity;
import android.content.ComponentName;
import android.content.Intent;
import android.os.Bundle;

/**
 * Invisible trampoline: opens Zee5's exported SplashActivity and exits.
 * Zee5's Mi TV build has no launcher intent, so this gives it a proper TV tile.
 */
public class MainActivity extends Activity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        Intent intent = new Intent(Intent.ACTION_MAIN);
        intent.setComponent(new ComponentName(
                "com.zee5.xiaomiTV",
                "com.zee5.splash.SplashActivity"));
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TOP);
        try {
            startActivity(intent);
        } catch (Exception ignored) {
            // Nothing else to do; the tile just does nothing if Zee5 is missing.
        }
        finish();
    }
}

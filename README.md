# Corvallis Bus for iOS
This is the iOS client for the [Corvallis Bus API](https://github.com/RikkiGibson/Corvallis-Bus-Server). It's freely available [on the App Store](http://appsto.re/us/iWJZ3.i). Compatible with iOS 8.0 and higher.

## Build
Run the following commands:
```
gem install bundler # If you don't have bundler installed already
bundler install # Installs Ruby-based dev dependencies
bundler exec xcake make # Generates the Xcode project
open CorvallisBus.xcworkspace
```

## Overview
#### Main app
The main app consists of 4 screens.

**1. Favorites**  
Allows users to quickly view arrival times for their favorite stops.

**2. Browse**  
Presents the bus stops in Corvallis on a map so that users can view detailed information about routes and arrival times.

**3. Service Alerts**  
Renders Corvallis Transit System's service alerts feed so that users can find out when to expect detours or interruptions in service.

**4. Preferences**  
Allows users to set a few preferences, such as whether to show the nearest stop in town in the Favorites view.

#### App extension
The app extension shows arrival information for the user's favorite stops in the Today view.

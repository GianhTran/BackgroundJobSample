# Summary

This project content 2 apps, one for android, one for ios, both of them have same purpose, that is tracking user location every 15s

- For Android: we use a Foreground service and a Handler to create a job to tracking user location every 15s, even app be killed 
- For iOS. we have a limitation, when app be killed, we can not execute code, but can record user location, and when the app getting back, we can load it from local store.

# Summary

This project content 2 apps, one for android, one for ios, both of them have same purpose, that is tracking user location every 15s

- For Android: we use a Foreground service and a Handler to create a job to tracking user location every 15s, even app be killed 
- For iOS. we have a limitation, when app be killed, we can not execute code, therefore no way to tracking location in this situation

# Netmobiel Front-end App Wrapper

The Flutter wrapper for the [Netmobiel Mobility-as-a-Service application](https://https://github.com/SaxionSmartCities/netmobiel-vue-client).

## Known issues
* The plugin flutter_webview_flutter cannot handle file input for loading an image. The webview_flutter_pro can.
* Redirection to keycloak for initial authentication does not work if navigation delegation is enabled. 
* The handling of the local banking app (redirection to the app) is not yet supported due to previous issue. 
* If navigation delegation is enabled, the return from the browser to the app by clicking the url does not return to the app.

 
## Flutter References
A few resources to get you started with Flutter:

- [Lab: Write your first Flutter app](https://flutter.dev/docs/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://flutter.dev/docs/cookbook)

For help getting started with Flutter, view our
[online documentation](https://flutter.dev/docs), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

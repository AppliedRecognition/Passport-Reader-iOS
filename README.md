# Ver-ID Passport Reader App

<img src="./Passport%20Reader/Assets.xcassets/Passport.imageset/passport@1x.png" align="right" alt="Passport" />

This app shows how to use the Ver-ID SDK to compare a face from a travel document to a selfie.

The app uses near-field communication (NFC) to read the chip embedded in machine-readable travel documents, such as passports.

The image from the travel document is then compared to a selfie captured using Ver-ID's face capture library.

The app doesn't store the captured document details or the captured face beyond the duration of the app's lifecycle.

The NFC capture is done using [NFCPassportReader](https://github.com/AndyQ/NFCPassportReader).
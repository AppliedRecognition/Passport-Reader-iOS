# Passport Reader iOS

Sample application that shows how to scan the chip of an e-Passport and compare the face on the passport to a live face.

The components in the application are:
- Microblink's [Blink ID](https://github.com/BlinkID/blinkid-ios) to scan the machine-readable zone (MRZ) on the passport's picture page
- Andy Q's [NFC Passport Reader](https://github.com/AndyQ/NFCPassportReader) to read the passports NFC chip
- Applied Recognition's [Ver-ID](https://github.com/AppliedRecognition/Ver-ID-UI-iOS) to capture a live face and compare it to the face from the passport's NFC chip

# PassID-iOS-App
iOS app client for PassID PoC.

# Usage
  Before running the app [PassID server](https://github.com/ZeroPass/PassID-Server) should be up and running.

  1. Open `PassID.xcodeproj` in Xcode
  2. Set `Team` account in `Signing & Capabilities`
  3. Run the app
  4. In the app go to settings and set server's URL address
  5. Close settings and go to `Register` screen
  6. Fill in data from passport
     e.g.: Passport number, date of birth and date of expiry
  7. Press `Scan` button and put your passport near your iPhone.
  8. If scan completes successfully and there is no communication error with the server,  
     you should end up on the `Success` screen 
  9. Go back and open `Login` screen
  10. Fill in data into form as in step 6 then follow step 7
  11. After successful login you can try to login again.
      This time the server should request your personal data from passport (EF.DG1 file).
      If you choose to send this file to the server it will return greeting with your name.

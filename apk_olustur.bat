@echo off
chcp 65001 > nul
echo ======================================================
echo   OlleysAPP - Android APK Olusturucu
echo ======================================================
echo.

where flutter >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [HATA] 'flutter' komutu sisteminizde bulunamadi!
    echo Windows Ortam Degiskenleri (PATH) icinde Flutter SDK 'bin' klasoru ekli olmayabilir.
    echo.
    pause
    exit /b 1
)

echo [1/1] Flutter APK Release Build baslatiliyor...
call flutter build apk --release
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [HATA] APK derleme sirasinda bir hata olustu! (Yukaridaki hata mesajini inceleyin)
    echo.
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo ======================================================
echo   APK BASARIYLA OLUSTURULDU!
echo   Dosya Konumu:
echo   build\app\outputs\flutter-apk\app-release.apk
echo ======================================================
echo.
echo Klasor aciliyor...
if exist "build\app\outputs\flutter-apk" (
    explorer "build\app\outputs\flutter-apk"
)
pause

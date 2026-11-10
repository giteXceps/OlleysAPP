@echo off
chcp 65001 > nul
echo ======================================================
echo   OlleysAPP - Web Surumu Derleniyor ve Yukleniyor
echo ======================================================
echo.

:: 1. Flutter Kontrolu
where flutter >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [HATA] 'flutter' komutu sisteminizde bulunamadi!
    echo Windows Ortam Degiskenleri (PATH) icinde Flutter SDK 'bin' klasoru ekli olmayabilir.
    echo.
    pause
    exit /b 1
)

:: 2. Web Build
echo [1/2] Flutter Web Release Build aliniyor...
call flutter build web --release
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [HATA] Flutter Web derleme sirasinda hata olustu! (Yukaridaki kirmizi mesaji inceleyin)
    echo.
    pause
    exit /b %ERRORLEVEL%
)

:: 3. Firebase Kontrolu & Deploy
echo.
echo [2/2] Firebase Hosting'e yukleniyor...

where firebase >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    call firebase deploy --only hosting
) else (
    echo 'firebase' komutu bulunamadi, npx ile deneniyor...
    call npx -y firebase-tools deploy --only hosting
)

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [HATA] Firebase yukleme basarisiz oldu!
    echo Oturum acilmamis olabilir. Terminalde 'npx firebase-tools login' calistirip giris yapin.
    echo.
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo ======================================================
echo   ISLEM BASARIYLA TAMAMLANDI!
echo   Web siteniz guncellendi.
echo ======================================================
pause

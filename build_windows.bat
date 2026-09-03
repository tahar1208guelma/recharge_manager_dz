@echo off
setlocal enabledelayedexpansion

echo ========================================================================
echo       RECHARGE MANAGER DZ - بناء نسخة الويندوز ومعالج التثبيت
echo ========================================================================

:: 1. التحقق من وجود أدوات C++ المطلوبة
echo [1/4] فحص مترجم Visual Studio C++ ...
where cl >nul 2>nul
if %errorlevel% neq 0 (
    echo.
    echo ------------------------------------------------------------------------
    echo [تنبيه] إذا طلب منك النظام Visual Studio C++ اثناء البناء:
    echo يمكنك تثبيته تلقائيا بكتابة الامر التالي في PowerShell:
    echo winget install Microsoft.VisualStudio.2022.BuildTools --override "--passive --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended"
    echo ------------------------------------------------------------------------
    echo.
)

:: 2. تنزيل حزمة Visual C++ Redistributable الرسمية من مايكروسوفت للمعالج
echo [2/4] تجهيز حزمة Visual C++ Redistributable (vc_redist.x64.exe) ...
if not exist "windows\installer\vcredist_x64.exe" (
    echo جاري تحميل vc_redist.x64.exe من مايكروسوفت...
    curl -L -o "windows\installer\vcredist_x64.exe" "https://aka.ms/vs/17/release/vc_redist.x64.exe"
)

:: 3. جلب حزم Flutter وبناء البرنامج
echo [3/4] جلب الاعتماديات وبناء البرنامج (Release Mode) ...
call flutter pub get
call flutter build windows --release

:: 4. فحص نتيجة البناء
echo [4/4] فحص الملف التنفيذي ...
if exist "build\windows\x64\runner\Release\recharge_manager_dz.exe" (
    echo.
    echo ========================================================================
    echo   تم بناء البرنامج بنجاح! 
    echo   مسار الملف التنفيذي:
    echo   build\windows\x64\runner\Release\recharge_manager_dz.exe
    echo ========================================================================
    echo.
    echo لإنشاء ملف Setup.exe لتثبيت البرنامج لدى الزبائن مع تثبيت C++ تلقائيا:
    echo افتح برنامج Inno Setup واضغط Compile على الملف:
    echo windows\installer\recharge_manager_dz_setup.iss
) else (
    echo.
    echo [خطأ] فشل البناء. يرجى التأكد من تثبيت حزمة "Desktop development with C++" في Visual Studio.
)

echo.
pause

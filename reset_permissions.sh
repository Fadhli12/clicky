#!/bin/bash
defaults delete com.yourcompany.leanring-buddy hasCompletedOnboarding 2>/dev/null
defaults delete com.yourcompany.leanring-buddy hasSubmittedEmail 2>/dev/null
defaults delete com.yourcompany.leanring-buddy hasScreenContentPermission 2>/dev/null
echo "Reset defaults."

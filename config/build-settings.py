#!/usr/bin/env python
"""
OpenXTalk Build Settings - Single Source of Truth
All version numbers and build configuration in one place
"""

class BuildSettings:
    """Central configuration for OpenXTalk builds"""
    
    # =========================================================================
    # macOS Settings
    # =========================================================================
    MACOS_MIN_DEPLOYMENT = '13.0'  # Minimum macOS version to run on
    MACOS_SUPPORTED_VERSIONS = [
        '13.0',  # Ventura
        '14.0',  # Sonoma  
        '15.0',  # Sequoia
    ]
    
    # =========================================================================
    # iOS Settings
    # =========================================================================
    IOS_MIN_DEPLOYMENT = '16.0'  # Minimum iOS version to run on
    IOS_SUPPORTED_VERSIONS = ['16.0', '17.0', '18.0']
    IOS_SIMULATOR_VERSIONS = ['16.0', '17.0', '18.0']
    
    # =========================================================================
    # Architecture Support
    # =========================================================================
    MAC_ARCHS = ['x86_64', 'arm64']
    IOS_ARCHS = ['arm64']  # Dropped armv7 support
    
    # =========================================================================
    # Build Configuration
    # =========================================================================
    DEFAULT_EDITION = 'community'
    DEFAULT_BUILD_MODE = 'debug'
    
    # =========================================================================
    # Development Requirements
    # =========================================================================
    MIN_XCODE_VERSION = '14.0'
    MIN_MACOS_FOR_BUILDING = '13.0'
    
    @classmethod
    def get_gyp_variables(cls):
        """Return settings as gyp variable dictionary"""
        return {
            'macos_deployment_target': cls.MACOS_MIN_DEPLOYMENT,
            'ios_deployment_target': cls.IOS_MIN_DEPLOYMENT,
            'default_edition': cls.DEFAULT_EDITION,
        }
    
    @classmethod
    def get_platform_list(cls):
        """Return list of supported platforms for gyp"""
        platforms = []
        for ver in cls.MACOS_SUPPORTED_VERSIONS:
            platforms.append(f'universal-mac-macosx{ver}')
        for ver in cls.IOS_SUPPORTED_VERSIONS:
            platforms.append(f'universal-ios-iphoneos{ver}')
        for ver in cls.IOS_SIMULATOR_VERSIONS:
            platforms.append(f'universal-ios-iphonesimulator{ver}')
        return platforms
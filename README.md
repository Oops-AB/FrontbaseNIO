# Frontbase for Vapor

## Prerequisites

This package is Swift wrapper for *FBCAccess* – the official C library for Frontbase –, which must be installed separately before using it in Swift projects.

_Note: the database itself does not need to be running, only the header and library files matter._

### Install Frontbase

Download an appropriate installer from the Frontbase [download page](http://www.frontbase.com/cgi-bin/WebObjects/FBWebSite).

### Setup Frontbase for pkgConfig

Swift requires a [pkgConfig](https://github.com/apple/swift-package-manager/blob/master/Documentation/PackageDescriptionV4.md#pkgconfig) configuration to find the header and library files.

Run the provided `setupFBCAccess.sh` script to install the required configuration file. It will `sudo`, so use an account that's in `sudoers`.

## Using Frontbase

This section outlines how to import the Frontbase package for use in a Vapor project.

Include the Frontbase package in your project's `Package.swift` file.

```swift
import PackageDescription

let package = Package(
    name: "Project",
    dependencies: [
        .package (url: "https://github.com/Oops-AB/FrontbaseNIO.git", from: "1.0.0"),
    ],
    targets: [ ... ]
)
```

The FrontbaseNIO package adds low level asynchronous Frontbase access to your project.

# Examples

## Setting up the Database

```swift
import FrontbaseNIO

	// Configure a Frontbase database
    let connection = try FrontbaseConnection.open (storage: .named (name: "Universe",
                                                                    hostName: "localhost",
                                                                    username: "_system",
                                                                    password: "secret"),
                                                   threadPool: threadPool,
                                                   on: eventLoop)
        .wait()
)
```

## Executing SQL

```swift
    let galaxyID = 1.frontbaseData!

    connection.query ("SELECT id, name FROM Planet WHERE galaxyID = ? ORDER BY name",
                      [galaxyID])
        .map { rows in
            rows.forEach { row in
                let id = row.firstValue (forColumn: "id")
                let name = row.firstValue (forColumn: "name")
    
                print ("Planet \(id?.description ?? "-"): \(name?.description ?? "-")")
            }
        }
        .wait()
```

## Contributors


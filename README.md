# Squirrel 🐿️

## Overview

This package offers modern asynchronous image loading functionality with an optimized cache for Apple platforms.
The loader can be used by itself, or via the conveniently provided SwiftUI view.

The package offers 2 libraries:
- ``Squirrel``: use it when you already have a UI for your images
- ``SquirrelUI``: use it when you want to seamlessly load and display your images

Test coverage is at 87%. 

## Topics

### Squirrel

This library offers modern asynchronous image loading functionality with an optimized cache for Apple platforms.

``Squirrel`` contains the ``AsyncImageCachingLoader`` class. 
It is thread safe and supports downloading an image from any URL.

### Loading

By default, ``AsyncImageCachingLoader`` uses the shared URLSession to load data.
This loading mechanism can be fully customized by injecting a closure with the requested signature.

### Caching
By default, ``AsyncImageCachingLoader`` uses an in-memory LRU cache based on `NSCache` with purge of stale data.
The behavior of this cache is as follows:
- When attempting to cache an entry, if the number of cached item has reached the specified count limit (100), the cache will remove the least used item from the cache before inserting the new entry.
- When reading an entry, if it has become stale, the cache will discard it and return no data. By default, an entry is considered stale if it was last accessed more than 12 hours ago.

Both the cache and loading mechanisms are fully customizable by injecting a closure with the requested signature.

### SquirrelUI

This library offers modern asynchronous image loading and displaying functionality 
with an optimized cache for Apple platforms.

``SquirrelUI`` offers an ``AsyncCachedImage`` view for loading and displaying images. 
Designed in the same spirit as [`AsyncImage`](https://developer.apple.com/documentation/SwiftUI/AsyncImage), 
it uses `AsyncImageCachingLoader` from `Squirrel` for loading images, allowing to enjoy all of its features.s.

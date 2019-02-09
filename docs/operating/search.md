---
title: Searching
parent: Operating
nav_order: 2
layout: default
---
## Searching

### What to Search
The app can search for Albums, Artists, Playlists and Tracks. Click on the Page Header text to switch between them.

### Wildcards
Spotify web-api search supports the '*' wildcard. It does not seem to search for substrings so if for example you search for 'Gubai' you will not find 'Gubaidulina'. When searching for 'Gubai_' you will find her.

Hutspot will append a '*' to the search string if not yet present to make searching easier but what if you want to search for a specific string? Then you don't want the wildcard to be added. So only if no wildcard is present in the query and no dash and no quote wildcard character is added at the end.

### Search History
The app saves your last queries. The Triangle on the right of the Search text allows you to select one.

# Judo

Judo is a proof-of-concept macOS application built with SwiftUI. It integrates with the `jj` version control system to visualize and interact with repository data using custom templates and revsets.

## Features

- Filter by revset query _or_ by description search. 
- Preview commit templates.
- Drag and drop commits to rebase them.
- Drag and drop bookmarks to move them.

## Danger Zone

* _IMPORTANT_ Use Judo at your own risk.
* Judo is (currently) using a Document based architecture in SwiftUI. Judo's documents are folders and SwiftUI isn't really set up to work like that. This means we have vestigal "Save" and "Revert" menu items that don't do anything except throw errors.

## Requirements

- `jj` installed at `/opt/homebrew/bin/jj`.

## License

This project is a proof of concept and is not intended for production use.

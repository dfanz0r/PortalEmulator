# PortalEmulator

The tldr goal here is to implement a emulated runtime environement for Battlefield portal typescript code, and spatial json data. And i'm doing it in the beef programming lanaguge because i found the language just as i was thinking about making this project and immediately wanted to use it on something.

Currently the project is very barebones and very work in progress but is composed of 2 main parts:

- Sizzle - this is the engine/library/framework side of the codebase
- PortalEmulator this is the main application code where all direct battlefield portal code will be implemented

I do want to address first since i get this question a lot, is that yes technically I could have implemented this inside of godot (or any other existing game engine), but honestly I didn't really feel like digging into how godot works under the hood.

The general plan for how this emulation layer will eventually be used:

- First the end user will need to download and provide a path to their portal sdk. Then this code will be able to load in the TSCN/GLB files for the maps and assets, which will give this custom runtime a basic graphic representation of the stock maps for testing purposes.

- Second we will have a project format that will let the tool know the location of your script and spatial json (or tscn) files, any game rules required.

Some general goals for the features i want to have:

- Script hot reloading
- Spatial json hot reloading
- Direct TSCN file loading/hotreload to enable quicker map iteration times
  - Advantage will be that we don't require exporting a json file each time to test gamemode + map.

This project is unlikely to implement a network layer for "multiplayer" since that is not the primary goal of this project.

## Project setup:

- Install Visual Studio 2022 w/ C++ desktop/gaming set in the installer
- Install the beef sdk from https://www.beeflang.org/
- Open workspace -> browse and select the PortalEmulator folder in the Beef IDE

It's pretty simple to get started!

## Likely future Dependancies

Currently these are dependancies that i know we will require but have not yet added

- Some version of QuickJS (or another easy to integrate JS runtime)
  - It seems BF6 uses some varient of QJS internally.
  - Original QuickJS - https://bellard.org/quickjs/
  - QuickJS-ng a fork - https://github.com/quickjs-ng/quickjs
- Will likely have a mix of Imgui for tool ui and custom ui layer for scripts to use.
- Will likely need to have a physics library, so https://github.com/jrouwe/JoltPhysics
- Will likely need https://github.com/recastnavigation/recastnavigation if we want to implement AI navigation systems on the maps
- https://github.com/wolfpld/tracy integration would be nice just for my own uses and frame profiling more generally.
- https://github.com/mackron/miniaudio for audio?
- Maybe https://github.com/guillaumeblanc/ozz-animation ?

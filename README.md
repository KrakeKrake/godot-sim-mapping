# godot-sim-mapping
Personal project to use procgen to make some cool maps.
Using Godot Game Enigne

## Generation
Use noise algoirthms to create the terrain. Overlays different noise values to create up to 17 different terrains.

There is are three noise maps for: Elevation, Temperature and Moisture


## Texture
The textures are made by processing all three noise maps in a shader.
Which dynamically shades on each pixel based on the how high, hot and moist that point is.

This effectivley means infinite resolution as no textures are actually involved *yet*
<img width="1977" height="1592" alt="image" src="https://github.com/user-attachments/assets/5ff56cec-a3c9-4aa9-a6a0-5058e86b804a" />

## Animation
There are currently only a few animations/special shaders.

First one I am most proud of is ice moving along the bottom:
https://github.com/user-attachments/assets/0c4eceef-e9f0-4208-95c0-3faa3a17e724

Second and third is small shaders on the ocean and reefs:
https://github.com/user-attachments/assets/49380bc9-a068-4d46-9a3c-c085899a4100
They are slow and hard to see, but they are there!

All of these animations were made painstakingly in shaders only, which is why they appear a bit uniform. But hopefully I will find a way to use Godot's animations for some.



## Creating boarders
It took some time to wrap my head around it, but I did for a bit understand it!

Effectivley, dot a bunch of random points and draw lines between them.  (Not truly random they are spaced out)
This creates triangles, you draw a circle that hits all three points of this traingle, and in the middle is the "capital" of the province (this capital part is called Voronoi diagram)
Because of maths, the capital is always within the bounds of the triangle.

Wikipedia does some more mathmatical explanations of it:
https://en.wikipedia.org/wiki/Delaunay_triangulation

Additionally, on top of these boaders, painstakingly, is another object, which will be the platform for allowing "clicking" on the provinces.
<img width="2126" height="1367" alt="image" src="https://github.com/user-attachments/assets/b18c8e14-0d4e-4b31-b2f9-5b9f175eef76" />
Currently they just give this pretty glass pane effect and allow me to show info on a hover.

# Currently be Rewritten 
Currently I am rewriting this in my spare time under different architectures for testing.

## Next Steps
The Plates is the most promising in order to get "realistic" looking planets, working on the border between the two plates is my current focus.
Should it turn out well, a combination between the plates and noise will be used, possibly then with the graphic components of the shader noise. Taking the best elements from all 3 developments.


## Experimenting with the following ideas:
### Initial Shading Method **(Is discussed below as the "main" method, this is no longer the case!)**:
  Used just 4 noises (and only one for elevation!)
  My only implementation of Biomes, allbeit very simple
  Shader texture generation meant infinite zoom, no generating images once a map is made.
  Did not look much like a "real" planet.
  **Crucuailly** The shader way of doing things did not allow for computation on the map, so making this go further would be difficult.
#### Current Look
  <img width="1686" height="963" alt="image" src="https://github.com/user-attachments/assets/bd6b3330-cd4b-4e24-8066-024e5e7cb8f1" />
  Was the most feature complete of the ideas, however, not necessarily the best for compute in the long run

### Purely Noise generated + large image as map:
  Low resolution and performance compared to shaders.
  Can be computed on.
  The current largest problem is: Noise doesn't make very "realistic" like planets, not much I can do to alter that.
  It can make an individual islands or continents look great, but not a planet.
  The current method has maps looking like Civ 6 Maps without the hexagons.
#### Current Look
  <img width="2012" height="1154" alt="image" src="https://github.com/user-attachments/assets/bebfe161-39d7-49c3-977f-5e96fefc31bb" />
  I am uniquely happy with how the oceans turned out. At a large enough scale this would be an amazing map.
  TODO: Do elevation maths on a shader: *Possibly* might allow for compute to be done still (not on the shader) while the shader does all of the texturing.

### Flood fill plates:
  Flood filling the plates is fun to watch, and does create realistic looking plates (I think)
  Hard time getting plates to interact realistically especially along their borders.
  May be worth while to return to this and add sub-plates or adjust parameters.
#### Current Look
<img width="1038" height="574" alt="image" src="https://github.com/user-attachments/assets/6432823b-b290-4ab3-8f91-3ef67e2b77ee" />
This one was very difficult to get even remotely correct, the plates are clearly shown however.
This is because along borders between plates there either needs to be: Mountains or Trenches
But the mountain or trench isn't just one pixel, it has to be "stamped" into the pixels around it.
Beyond that plates are either continental or oceanic (which sets their "base height"), which explains the stark differenence between them
Blending between the plates is the hardest obstacle to overcome.

### Map Graph
This is currently empty, as I want to explore the other ideas to their fullest first.
I would be aiming for a more complex implementation similar to: https://azgaar.github.io/Fantasy-Map-Generator/
Which is an amazing project for quickly making fantasy maps.




# Currently be Rewritten 
Currently I am rewriting this in my spare time under different architectures for testing.

## Next Steps
I have started graph map development and will continue working on it when I get free days (like today yayy, but not tommorow :( ), the next step is to work a bit further on moisture and then get biomes working.
The step after that will be working on texturing, then likely a review of my system so far, optimisations, and where to head next regarding simulation hopefully.


## Current State
<img width="1979" height="754" alt="image" src="https://github.com/user-attachments/assets/9082da7f-faea-4644-8f62-75c074b244c9" />
As of the latest push this is what the map looks like, it is, amazingly, the result of *another* rewrite. I think this is the direction I will continue to pursue. 
This is the graph map, previously I didn't want to pursue it, but since I worked on it (this video here was very helpful in understanding how to create voronoi diagrams: https://www.youtube.com/watch?v=I6Fen2Ac-1U, in addition to this blog by Red Blob Games: http://www-cs-students.stanford.edu/~amitp/game-programming/polygon-map-generation/, and this one by the creator of Azgaar's Fantasy Map Generator: https://azgaar.wordpress.com/2017/03/30/voronoi-graph/)

My previous hesitence on this idea came from: Provinces are dirty. And I maintain that, they are not perfect. In a perfect world we could create provinces from a heightmap, which is still an avenue I may explore, but right now this map generates a number of provinces, and then gets data from them, from a heightmap. (Earth Pictured Below, sort of).

<img width="3114" height="1238" alt="image" src="https://github.com/user-attachments/assets/95576255-25a3-491f-942e-1d137c0de833" />
Notably missing the UK, Carribean, Japan and all of South East Asia... because sea levels need tuning, WAKE UP TO CLIMATE CHANGE GUYS THIS IS WHAT IS GONNA HAPPEN.

With high province counts (this earth map was 20,000 provinces) the map actually looks better than expected, it is distringuisable but not incredible. I believe that as a problem will cease with custom maps, as the earth is too easy to have expectations for. 
A problem I do have though is, ocean provinces, I want to combine them. So I will have to generate provinces that are then removed, basically wasting resources. But that isn't an *awful* tradeoff. Performance is... not great, lots of primitives being drawn every frame, generation is O(n^2) sadly, I do plan to rewrite it with GDExtension some day for more performance, for testing this is acceptable though.

## Features I am proud of
- Multi threading generation. A problem with basically every map I have worked on, and a killer of provinces before. To achieve this I generate one set of provinces first, single threaded (about 100-300 of them I find is best), then in each of those I create more provinces, with threads. However this has drawbacks, namely that now provinces are more likely to have jagged uniform lines that look rather unnatrual. But I found that is only visible in some scenarios, and if you are looking for it.
- Wind. I modeled wind. Yes, wind. Honestly much easier than I anticipated, getting realistic looking wind currents (looking is the key word) was easier than I expected. The x and y direction of the wind comes from two different noises, and the strength of the current comes from a third. Each province now has a wind direction and speed. Wind pictured, the red lines representing where the wind is headed from the centre of each province (red circle): <img width="1813" height="705" alt="image" src="https://github.com/user-attachments/assets/1e5d1917-d596-4272-89b9-0c1e4280985f" />


- Moisture, the aim of the wind above was to try and model moisture, it is still a work in progress, but does work. Essentially wind picks up moisture and sends it inland. This will be combined with a few other features to create basic biomes. On the maps the white bits represent the amount of moisture currently for debugging.
- Provinces without gaps. A major problem I faced before was that the provinces would be, what felt like randomly, deleted when I tried to trim all of their areas to just the screen area. However thanks to the youtube video I linked above, I apporached provinces with a new idea in mind, not using delunay triangulation, but bisectors. Which is much simpler to understand.
- Heightmap Compatibility. All of the methods below I experiment with can output to heightmaps, so my effort on them is not entirely wasted. In testing infact I am using a heightmap that I created with the "Purely Noise Generated" method. Also, as above with the earth, heightmaps are a great compatibility layer, so long as any generator can output to a heightmap, basically any map can be used, including ones that much improve upon mine, such as the Terrain Diffusion project, which I salivate at.


## Experimented with the following ideas, may be used going forwards but will unlikely be main methods:
### Initial Shading Method:
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




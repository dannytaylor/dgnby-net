![](https://raw.githubusercontent.com/dannytaylor/dgnby/master/release/cart.png)
### dog 'n boy online
this is a proof of concept for a networked tic-80 cart. it is a modification of an [existing demo cart of mine](https://neopolita.itch.io/pico8com) made with a [modified version of tic-80](repo_to_come_later).

I'm roughly following [pico8's](https://www.lexaloffle.com/pico-8.php?page=manual) implementation of it's gpio memory which is shared with the browser as the array *tic80_gpio* then synced with the connected player over a peer 2 peer connection. I've hijacked the 16 bytes starting from 0xff8c in this modified tic80 version for this purpose - this game uses the first 8 bytes as the local player's data and second 8 as player 2's.

there's basically no error handling for peer connections issues and I've turned off direct/lobby connections for testing.

### resources
- **[tic-80](https://github.com/nesbox/TIC-80)** by [nesbox](https://twitter.com/tic_computer)
- **[simple-peer](https://github.com/feross/simple-peer)** by [feross](https://twitter.com/feross) for webrtc implementation
- **[moonscript](https://github.com/leafo/moonscript/)** by [leaf](https://twitter.com/moonscript) for game cart
- **[eroge copper](https://lospec.com/palette-list/eroge-copper)** by [arne](https://twitter.com/AndroidArts) colour palette
- **[google firebase](https://firebase.google.com/)** for signal data exchange
- **[tic-80 font](https://fontstruct.com/fontstructions/show/1388526/tic-80-wide-font)** by [fred bednarski](https://twitter.com/FredBednarski)

### useful reading and projects 
- [simple-peer + firebase implementation](https://dev.to/rynobax_7/creating-a-multiplayer-game-with-webrtc)
- [pico8 gpio implementation](https://www.lexaloffle.com/bbs/?tid=3909)
- [moonscript rundown](https://github.com/leafo/moonscript/wiki/Learn-MoonScript-in-15-Minutes)
- [pico8 websocket networking](https://neopolita.itch.io/pico8com)

:runner:  :dog2:

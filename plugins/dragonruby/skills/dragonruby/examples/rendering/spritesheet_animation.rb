# Spritesheet animation using tile_x and tile_y

def tick args
  args.state.player ||= { x: 640, y: 360, w: 64, h: 64 }

  moving = args.inputs.left || args.inputs.right

  if moving
    args.state.run_start ||= Kernel.tick_count

    # 6 frames, 3 ticks each, looping
    tile_index = args.state.run_start.frame_index(6, 3, true)

    args.outputs.sprites << {
      x: args.state.player.x,
      y: args.state.player.y,
      w: args.state.player.w,
      h: args.state.player.h,
      path: 'sprites/horizontal-run.png',
      tile_x: tile_index * 64,
      tile_y: 0,
      tile_w: 64,
      tile_h: 64,
      flip_horizontally: args.inputs.left
    }
  else
    args.state.run_start = nil

    args.outputs.sprites << {
      x: args.state.player.x,
      y: args.state.player.y,
      w: args.state.player.w,
      h: args.state.player.h,
      path: 'sprites/horizontal-stand.png'
    }
  end

  args.outputs.labels << { x: 640, y: 100, text: "Hold LEFT/RIGHT to run", anchor_x: 0.5 }
end

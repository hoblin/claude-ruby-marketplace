# Filled rectangles and backgrounds

def tick args
  # Solid background
  args.outputs.solids << [0, 0, 1280, 720, 32, 32, 32]

  # Array syntax: [x, y, w, h, r, g, b, a]
  args.outputs.solids << [100, 500, 100, 100]
  args.outputs.solids << [220, 500, 100, 100, 255, 0, 0]
  args.outputs.solids << [340, 500, 100, 100, 0, 255, 0, 128]

  # Hash syntax (recommended)
  args.outputs.solids << {
    x: 460, y: 500, w: 100, h: 100,
    r: 0, g: 128, b: 255, a: 200
  }

  # path: :solid for better performance with many rectangles
  args.outputs.sprites << {
    x: 580, y: 500, w: 100, h: 100,
    path: :solid,
    r: 255, g: 255, b: 0
  }

  # Borders (outlined rectangles)
  args.outputs.borders << [100, 300, 100, 100, 255, 255, 255]
  args.outputs.borders << { x: 220, y: 300, w: 100, h: 100, r: 0, g: 255, b: 255 }
end

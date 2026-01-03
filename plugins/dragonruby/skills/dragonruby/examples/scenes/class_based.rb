# Class-Based Scene Management
# Full OOP approach for complex games
# Source: DragonRuby samples/02_input_basics/07_managing_scenes_advanced

class Game
  attr :args, :hp

  def initialize
    @hp = 100
  end

  def take_damage
    @hp -= 10
  end

  def heal
    @hp += 10
  end

  def dead?
    @hp <= 0
  end

  def restart
    @hp = 100
  end
end

class TitleScene
  attr :args

  def id
    :title
  end

  def tick
    args.outputs.labels << {
      x: 640, y: 400,
      text: "Click to Start",
      anchor_x: 0.5
    }

    if args.inputs.mouse.click
      args.state.next_scene = :gameplay
    end
  end
end

class GameplayScene
  attr :game, :args

  def initialize(game)
    @game = game
  end

  def id
    :gameplay
  end

  def tick
    # Damage on Enter
    if args.inputs.keyboard.key_down.enter
      @game.take_damage
    end

    # Check death
    if @game.dead?
      args.state.next_scene = :game_over
    end

    # Render
    args.outputs.labels << {
      x: 640, y: 400,
      text: "HP: #{@game.hp} (press Enter to take damage)",
      anchor_x: 0.5
    }
  end
end

class GameOverScene
  attr :game, :args

  def initialize(game)
    @game = game
  end

  def id
    :game_over
  end

  def tick
    args.outputs.labels << {
      x: 640, y: 400,
      text: "Game Over! Click to restart",
      anchor_x: 0.5
    }

    if args.inputs.mouse.click
      @game.restart
      args.state.next_scene = :title
    end
  end
end

class SceneManager
  attr :args

  def initialize
    @game = Game.new
    @scenes = [
      TitleScene.new,
      GameplayScene.new(@game),
      GameOverScene.new(@game)
    ]
  end

  def tick
    args.state.scene ||= :title

    scene_before = args.state.scene

    # Find and tick current scene
    scene = @scenes.find { |s| s.id == args.state.scene }
    raise "Scene #{args.state.scene} not found!" unless scene

    scene.args = args
    scene.tick

    # Validate no mid-tick change
    if args.state.scene != scene_before
      raise "Don't change scene directly. Use args.state.next_scene"
    end

    # Apply deferred transition
    if args.state.next_scene
      args.state.scene = args.state.next_scene
      args.state.next_scene = nil
    end
  end
end

def tick args
  $manager ||= SceneManager.new
  $manager.args = args
  $manager.tick
end

def reset args
  $manager = nil
end


$gtk.reset

GRID_WIDTH = 1280 
GRID_HEIGHT = 150
TILE_SIZE = 50
TILE_WIDTH = 1280 / 4
ROWS = GRID_WIDTH / TILE_WIDTH
COLS = GRID_HEIGHT / TILE_SIZE
ARROW_SPAWN_POINT = 720

class FujiwaraGame
  

#cambiar los valores de la clase arrow de y a current_arrow y de points a @minus_points


#Arreglar bug en función de sequence
#Agregar particle effects cada que apretes el botón 
#Hacer que no dar el input correcto sea también un error
#Lluvia de ideas de como terminar las secuencias para que no acaben ántes
#Agregar formas de reiniciar el juego en la pantalla de game over





  def initialize args
    @args = args
    @screen_width = 1280
    @screen_height = 720
    @game_started ||= true
    @score ||= 50
    @grid ||= Array.new(ROWS) { Array.new(COLS, 0) }
    @current_arrow ||= false
    @next_arrow ||= nil
    @half_points = 0
    @full_points = 1
    @minus_points = -1
    @easy = 3
    @normal = 4
    @hard = 6
    @pendejo = 10
    @arrow_fall_speed ||= @normal
    @game_over ||= false
    @timer ||=  92
    @k = @args.inputs.keyboard
    @title_screen_passed ||= false
    @splash_timer = 0
    
    
    
  end

  class Arrows
    def initialize (x, r, g, b)
      @x = x * TILE_SIZE #arrow_spawn_point
      @y = ARROW_SPAWN_POINT
      @w = TILE_SIZE
      @h = TILE_SIZE
      @r = r
      @g = g
      @b = b
      
      @points = -1 #minus_points

    end

    def arrow_creator 
     {x: @x, y: @y, w: @w, h: @h, r: @r, g: @g, b: @b, points: @points}
      
    end
  end



  def game_state
    if @args.state.game_over 
      return game_over_state()
    elsif !@args.state.game_over && !@args.state.game_started 
      return main_menu_state()
    else
      return gameplay_state()
    end
    
  end

  def gameplay_state
    fujiwara_song_flag()
    fujiwara_song()
    render()
    game_timer()
    arrow_sequences()
    arrow_movement()
    score_system()
    arrow_collision()
    user_input()
    health_bar()
    game_over()
  end

  def game_over_state
    fujiwara_song()
    game_voice_flag()
    sound_effects()
    render_game_over()
    game_over_screen()
    restart_game()
    debug()
  end

  def main_menu_state
    sound_effects()
    if @title_screen_passed
      options()
      render_main_menu()
    else 
      title_and_splash_screen()
      render_title_and_splash_screen()
    end

  

    debug()
  end

  def sound_effects
    
    @welcome ||= "sounds/sound_voices/welcome_audio.mp3"
    @excelent ||= "sounds/sound_voices/excelent_audio.mp3"
    @good ||= "sounds/sound_voices/good_audio.mp3"
    @mid ||= "sounds/sound_voices/mid_audio.mp3"
    @bad ||= "sounds/sound_voices/bad_audio.mp3"
    @how_cute ||= "sounds/sound_voices/how_cute.mp3"
    @chontiago ||= "sounds/sound_voices/chontiago_makes_games.mp3"
    @game_over_voice ||= @mid
  end
  
  #This set of functions set up and draw the game
  def render
    render_video()
    render_grid()
    #debug
    render_arrows()
    render_hud()
    
  end

  def render_grid 
      counter ||= 0
      @grid.each_with_index do |row, x|
        row.each_with_index do |cell ,y|
          grid_traits = {x: x * TILE_WIDTH, y: y * TILE_SIZE, w: TILE_WIDTH, h: TILE_SIZE, r: 0, g: 0, b: 0, points: 0, contact: false}
          @grid[x][1] = @full_points # half_points == 0 so no need to set value for the rest of the grid

          @grid[x][y] == 1 ? grid_traits[:g] = 255 : (grid_traits[:g] = 255; grid_traits[:r] = 255) #Changes grid color depending on points it gives

          @args.outputs.solids << grid_traits
        
       
        end
      end
    
    end


  def render_hud
    @hud_height ||= -80
    @args.outputs.solids << [0, @screen_height, @screen_width, @hud_height, 0, 0, 0 ]
    
    @score_graph = {x: 1150, y: 680, anchor_x: 0.5, anchor_y: 0.5, r: 255, g: 255, b: 0, text:  "SCORE #{@score}"}
    @args.outputs.labels << @score_graph
    
  
  end

  def render_arrows
    @main_sequence.each do |arrow|
      @args.outputs.primitives << arrow.solid
    end
  end

  def render_video
    video()
  
    #Render the PNG image as the background
    @args.outputs.primitives << @video_image.sprite
  end

  #This set of functions give the game the logic to work

  def arrow_generator #Generates arrows to add to the sequence 
    @left_arrows = []
    @up_arrows = []
    @down_arrows = []
    @right_arrows = []
    
    500.times do |i| # Increase or decrease number of times depending of number and complexity of sequences
      @left_arrows << Arrows.new(3, 255, 0, 0).arrow_creator
      @up_arrows << Arrows.new(9, 255, 102, 0).arrow_creator
      @down_arrows << Arrows.new(14, 0, 0, 255).arrow_creator
      @right_arrows << Arrows.new(20, 255, 0, 255).arrow_creator
    end

  end


  def arrow_sequences  #Creates the sequences of arrows, and selects the current arrow for the user to interact with it
    
    arrow_generator()

    @main_sequence ||= []
    #Aquí está el bug, el juego agarra aleatoriamente a veces la misma flecha cuando se repite
    @sequence1 = [ @left_arrows.sample, @up_arrows.sample, @down_arrows.sample, @right_arrows.sample ]
    @sequence2 = [ @up_arrows.sample, @down_arrows.sample, @up_arrows.sample, @right_arrows.sample ] 
    @sequence3 = [ @up_arrows.sample, @down_arrows.sample, @up_arrows.sample, @down_arrows.sample ]
    @sequence4 = [ @left_arrows.sample, @down_arrows.sample, @left_arrows.sample, @right_arrows.sample, @up_arrows.sample]
    @sequence5 = [ @right_arrows.sample, @left_arrows.sample, @down_arrows.sample, @left_arrows.sample ]
    @sequence6 = [ @down_arrows.sample, @down_arrows.sample, @up_arrows.sample, @left_arrows.sample, @right_arrows.sample, @up_arrows.sample]
    #@sequence7 = [ @down_arrows.sample, @up_arrows.sample, @right_arrows.sample, @left_arrows.sample, @down_arrows.sample, @up_arrows.sample, @right_arrows.sample ]



    @all_sequences = [ @sequence1, @sequence2, @sequence3, @sequence4, @sequence5, @sequence6 ]

    
    if @timer > 0
      if @main_sequence.empty?
        @main_sequence = @all_sequences.sample 
      end
    end
      
    
    @current_arrow = @main_sequence[0]
  
  end

  def arrow_movement

    
    next_arrow_move = ARROW_SPAWN_POINT - 100 #when arrow reaches this distance, the next arrow starts moving
    
    @main_sequence[0][:y] -= @arrow_fall_speed #moves first arrow
    
    

    @main_sequence.each_with_index do |arrow, index|  #moves next arrows
      if @main_sequence[index][:y] <= next_arrow_move && @main_sequence[index + 1] != nil 
        @main_sequence[index + 1][:y] -= @arrow_fall_speed
        
      end
      

      
      
    end

  end

  def arrow_collision
    
    @grid.each_with_index do |row, x|
      row.each_with_index do |cell, y|
        grid_traits = {x: x * TILE_WIDTH, y: y * TILE_SIZE, w: TILE_WIDTH, h: TILE_SIZE, r: 0, g: 0, b: 0, points: 0, contact: false}
        

        if collision(@current_arrow, grid_traits) 
          #@args.outputs.labels << {x: 1280 / 2, y: 720 / 2, anchor_x: 0.5, anchor_y: 0.5, r: 0, g: 0, b: 0, text:  "COLLISION"}
          @grid[x][y] == @full_points ? @current_arrow[:points] = @full_points : @current_arrow[:points] = @half_points

          @current_arrow = @main_sequence[0]
        end
      end
    end
  end

  def collision(box1, box2)
    #box1[:y] < box2[:y] + box2[:h] &&
    #box1[:y] + box1[:h] > box2[:y]
    #box1[:x] >= box2[:x] && box1[:x] <= box2[:x] + box2[:w] &&
    box1[:y] >= box2[:y] && box1[:y] <= box2[:y] + box2[:h]
  
  end

  def user_input
    #Arrow controls
    #These variables represent the x position in created arrows to compare them with their corresponding key

    left_arrow ||= @left_arrows.sample[:x]
    up_arrow ||= @up_arrows.sample[:x]
    down_arrow ||= @down_arrows.sample[:x]
    right_arrow ||= @right_arrows.sample[:x]


    
    correct_input ||= nil
    
    


    case @current_arrow[:x]
    when left_arrow
      correct_input = @k.key_down.a
    when up_arrow
      correct_input = @k.key_down.s
    when down_arrow
     correct_input = @k.key_down.d
    when right_arrow
     correct_input = @k.key_down.f
      
    end

    if correct_input
      return true
    end


  end



  def score_system
    

    if user_input 
      @current_arrow[:y] = ARROW_SPAWN_POINT #Reseting arrow_y before shifting is important, improves performance, and fixes some arrow_creation bugs
      @main_sequence.shift
      #@arrow_fall -= @arrow_fall_speed
      if @current_arrow[:points] == @full_points
        @score += 10
      elsif @current_arrow[:points] == @half_points
        @score += 5
      elsif @current_arrow[:points] == @minus_points
        @score -= 10
      end
    end

    
    
    if @current_arrow[:y] <= 0
      @score -= 10
      @current_arrow[:y] = ARROW_SPAWN_POINT #Reseting arrow_y before shifting is important, improves performance, and fixes some arrow_creation bugs
      @main_sequence.shift
      #@arrow_fall -= @arrow_fall_speed
    end

    if @score >= 100
      @score = 100
    
    end

    
    
    
  end

  def fujiwara_song
    
    @args.audio[:music] ||= {
      input: "sounds/music/Fujiwara_song.ogg",
      gain: 0.5,
      looping: false,
      paused: true
    }

    if @song_started
      @args.audio[:music].paused = false
    
    end

    if @args.state.game_over
      @args.audio[:music].paused = true
    end
  end

  def fujiwara_song_flag
    @song_started ||= false
    @song_counter ||= 0
    @song_counter += 1

    if @song_counter == 3 * 60
      @song_started = true
    end
  end

  def video
    @video_frame_counter ||= 0
    x = 0
    y = TILE_SIZE * 3
    w = 1280
    h = (720 - 80) - y # Adjusted for the HUD height

    @video_frame_counter +=1
    @video_image = { x: x, y: y, w: w, h: h, path: "video/#{@video_frame_counter}.png"}

    if @video_frame_counter >= 5878 #The last frame of the video
      @video_frame_counter = 5878
    end
    
     
  end
  

  def health_bar
    if @score == 100
      @score_graph[:r] = 0
      @score_graph[:b] = 0
    elsif @score >= 75
      @score_graph[:r] = 199
      @score_graph[:g] = 234
      @score_graph[:b] = 70
    elsif @score >= 50
      @score_graph[:b] = 0
    elsif @score >= 25
      @score_graph[:r] = 255
      @score_graph[:g] = 105
    else
      @score_graph[:g] = 0 
      @score_graph [:b] = 0 
    end
  end


  def game_timer
    timer_seconds = 1 / 60 #One second every frame
    
    @timer -= timer_seconds
    
  
  end
  


  def game_over
    if @timer <= 0 && @main_sequence[0] == nil
      @args.state.game_over = true
      @args.state.game_started = false
      
    end

    if @score <= 0
     @args.state.game_over = true
     @args.state.game_started = false
     
    end
    

  end

  ##Game over state code
  def render_game_over
    game_over_screen()
    
    

   
    @args.outputs.primitives << {x: 0, y: 80, w: 1280, h: 720 - 80, path: @score_screen}.sprite
    @args.outputs.primitives << {x:0, y:0, w:1280, h: 80}.solid
    @args.outputs.labels << {x: 1280 / 2, y: 50, anchor_x: 0.5, anchor_y: 0.5, r: 255, g: 8, b: 127, text:"#{@game_over_message}" ,size_enum: 5, font_style: 'bold'}
    @args.outputs.labels << {x: 1280 / 2, y: 20, anchor_x: 0.5, anchor_y: 0.5, r: 255, g: 255, b: 255, text:"PRESS SPACEBAR TO RESET" ,size_enum: 3, font_style: 'bold'}
     
  if @sound_clip == true
    @args.outputs.sounds << @game_over_voice
  end 
     
  
  end

  def game_voice_flag
    @sound_clip = false
    @counter ||= 0
    @counter +=1

    if @counter == 2 
      @sound_clip = true
    end
    


  end
 
  def game_over_screen
    @score_screen  ||= ""
    @game_over_message ||= ''


   
    
    if @score == 100
      @score_screen = "game_over/excelent.jpeg"
      @game_over_message = "YOU DID A TANK CLASS JOB "
      @game_over_voice = @excelent
    elsif @score >74 && @score < 100 
      @score_screen = "game_over/good.jpg"
      @game_over_message = "YO YO YO, GREAT JOB"
      @game_over_voice = @good
    elsif @score > 49 && @score < 75
      @score_screen = "game_over/mid.jpg"
      @game_over_message = "NOT STUDENT COUNCIL WORTHY "
      @game_over_voice = @mid
    elsif @score > 0 && @score < 50
      @score_screen = "game_over/bad.jpeg"
      @game_over_message = "OH NO YOU NEED EVEN MORE HELP THAN KAICHOU"
      @game_over_voice = @bad
    else
       @score_screen = 'game_over/lose.png'
       @game_over_message = ""
       @game_over_voice = @how_cute
    end
  end

  def game_over_voices
    
  end

  def restart_game
    if @k.key_down.space 
      $gtk.reset    
    end
  end
  
  # Main menu code

 
  def render_main_menu
    
    render_background()
    render_options()
    
  
  end
  
  def render_background

    main_menu_background = { x: 0, y: 0, w: 1280, h: 720, path: "main_menu/fujiwara_main_menu.png"}
    @args.outputs.primitives << main_menu_background.sprite
  end

  def render_options
    
    
    text_x_alignement = -500
    text_y_alignement = -100
    @options_tile_size = 100
    
    @current_options ||= @main_options
    
    @current_options.each_with_index do |options, index|    
      option_select_text = {x: 1280 + text_x_alignement, y:(@screen_height + text_y_alignement ) + (-index * @options_tile_size), anchor_x: 0.5, anchor_y: 0.5, r: 255, g: 255, b: 255, text:  "#{options}",size_enum: 4, font_style: 'bold'}
      
      
      @args.outputs.labels << option_select_text
    end
  end

  def render_title_and_splash_screen
    @args.outputs.primitives << {x: 0, y: 0, w: 1280, h: 720, path: @title_and_splash_screen}.sprite


  end


  def title_and_splash_screen
    splash_screen_time = 2 * 60 # 3 seconds
    
    @title_and_splash_screen ||= "main_menu/splash_screen.jpeg"

    @splash_timer += 1
    
    
    if @splash_timer >= splash_screen_time 
      @title_and_splash_screen = "main_menu/fujiwara_title_screen.jpeg"
      @args.outputs.labels << {x: 1280 / 2, y: 25, anchor_x: 0.5, anchor_y: 0.5, r: 255, g: 8, b: 127, text:  "PRESS SPACEBAR TO START" ,size_enum: 5, font_style: 'bold'}
      
      
    
      if @k.key_down.space 
        @title_screen_passed = true
        @args.outputs.sounds << @welcome
      end
    else
      @args.outputs.sounds << @chontiago
    end
  end

  def options
    @main_options = [ 'PLAY', 'DIFFICULTY', 'CONTROLS', 'QUIT' ]

    difficulty = [ "CHIKA'S CHARM", 'FUJIWARA FUN', 'CHIKA CHALLENGE', 'FUJIWARA FRENZY','BACK']

    controls = ["W RED", "S ORANGE", "D BLUE", "F PURPLE", "BACK"]

    @options_tile_width = 50000
    box_x_alignement = -600
    box_y_alignement = -150
  
    
    
    @current_options.each_with_index do |options, index|    
      option_select_hitbox = {x: 1280 + box_x_alignement, y:(@screen_height + box_y_alignement ) + (-index * @options_tile_size), w: @options_tile_width, h: @options_tile_size }
      if @args.inputs.mouse.click
        if collision(@args.inputs.mouse.point, option_select_hitbox)
          case options
          when "PLAY"
            @args.state.game_started = true
          when "DIFFICULTY"
            @current_options = difficulty 
          when "CONTROLS"
           @current_options = controls
          when "QUIT"
            exit(0)
          when "CHIKA'S CHARM"
            @arrow_fall_speed = @easy
            @current_options = @main_options
          when "FUJIWARA FUN"
            @arrow_fall_speed = @normal
            @current_options = @main_options
          when "CHIKA CHALLENGE"
            @arrow_fall_speed = @hard
            @current_options = @main_options
          when "FUJIWARA FRENZY"
            @arrow_fall_speed = @pendejo
            @current_options = @main_options
          when "BACK"
            @current_options = @main_options
          end
          
        end
      
      end
    end
  end

  def game_start
    if @k.key_down.space
      @args.state.game_started = true 

      

    end
  end

  

  def debug 
    @args.outputs.labels << {x: 1280 / 2, y: 720 / 2, anchor_x: 0.5, anchor_y: 0.5, r: 0, g: 0, b: 0, text:  "#{@args.state.music_over}"}
    #@args.outputs.labels << {x: 200, y: 400, anchor_x: 0.5, anchor_y: 0.5, r: 0, g: 0, b: 0, text:  "#{@sound_clip}"}
    
  end

  
  def tick
   game_state
  end

end



def tick args
  game_started_and_game_over(args)
  #music_started_and_music_over(args)
  args.state.game ||= FujiwaraGame.new args
  args.state.game.tick

end

def game_started_and_game_over(args)
  args.state.game_over ||= false
  args.state.game_started ||= false

  
end

using GLMakie
using CoordinateTransformations
using Rotations

BOARD_SIZE = (256, 256)
FILL_PERCENTAGE = 0.5
FIG_UPSCALE = 4

include("Projection.jl")
include("Geometry.jl")
include("Line.jl")

board = rand(Float64, BOARD_SIZE) .> FILL_PERCENTAGE .|> Float64;

function draw(data)
    fig = Figure(resolution=BOARD_SIZE .* FIG_UPSCALE, backgroundcolor=:black)
    ax = Axis(fig[1, 1], aspect=DataAspect())

    hidedecorations!(ax)
    hidespines!(ax)
    deregister_interaction!(ax, :dragpan)
    deregister_interaction!(ax, :rectanglezoom)
    deregister_interaction!(ax, :scrollzoom)

    # register_interaction!(ax, :click) do event::MouseEvent, axis
    #     if event.type == MouseEventTypes.leftclick
    #         global last_point, current_point

    #         last_point = to_value(current_point)
    #         current_point[] = floor.(Int, event.data)
    #     end
    # end

    img = image!(ax, data, interpolate=false, colorrange=(0, 1), colormap=:grays)
    # Colorbar(fig[1,2], img, label = "Density")
    return Makie.FigureAxisPlot(fig, ax, img)

end

function flip!(board, points)
    for p in points
        if CartesianIndex(p) in CartesianIndices(BOARD_SIZE)
            board.val[p...] = 1.0 - board.val[p...]
        end
    end
end

function blit!(board, points)
    board.val = zeros(Float64, BOARD_SIZE)
    for p in points
        if CartesianIndex(p) in CartesianIndices(BOARD_SIZE)
            board.val[p...] = 1.0
        end
    end
    notify(board)
end

## Draw

board = Observable(Float64.(rand(Float64, BOARD_SIZE)) .< 0.5);
# board = Observable(zeros(Float64, BOARD_SIZE))

camera_pos = [-1.5, -1.5, 1]
camera_transform = PerspectiveMap() ∘ inv(AffineMap(I, camera_pos))

my_cube = UnitCube()

my_cube.vertices = Translation(-0.5, -0.5, 4-0.5).(my_cube.vertices)

flip!(board, draw_wireframe(my_cube, camera_transform, BOARD_SIZE))

fig, ax, img = draw(board)

# camera_sliders = SliderGrid(
#     fig[2,1],
#     (label = "X", range=-3:0.1:3, startvalue=-1.5),
#     (label = "Y", range=-3:0.1:3, startvalue=-1.5),
#     (label = "Z", range=-10:0.01:10, startvalue=1)
# )

# time_slider = Slider(fig[3,1], range=0:0.1:10, startvalue=0)

# camera_slider_observables = [s.value for s in camera_sliders.sliders]

# camera_node = lift(camera_slider_observables...) do vals...
#     global camera_pos = [vals...]
# end


# on(camera_node) do new_cam
#     cube = UnitCube()
#     camera_transform = PerspectiveMap() ∘ inv(AffineMap(I, camera_pos))
#     cube.vertices = Translation(-0.5, -0.5, 4-0.5).(cube.vertices)
#     blit!(board, draw_wireframe(cube, camera_transform, BOARD_SIZE))
#     notify(board)
# end

screen = fig

## Animate 
t = 0.0
running = true

while events(fig.scene).window_open.val
    cube = UnitCube()

    camera_transform = PerspectiveMap() ∘ inv(AffineMap(I, camera_pos))
    cube.vertices = (Translation(0,0,4) ∘ LinearMap(RotY(t/10) * RotX(sqrt(2)*t/10) * RotZ(pi*t/10)) ∘ Translation(-0.5, -0.5, -0.5)).(cube.vertices)

    flip!(board, draw_wireframe(cube, camera_transform, BOARD_SIZE))
    notify(board) 

    t += 0.1
    sleep(0.01);
end

## Animate & save

framerate = 60
Nframes = 60*5 
delta_t = 0.1
time = 0.0:delta_t:delta_t*(Nframes-1)

record(fig, "cube.mp4", time; framerate=framerate) do t
    cube = UnitCube()

    camera_transform = PerspectiveMap() ∘ inv(AffineMap(I, camera_pos))
    cube.vertices = (Translation(0,0,4) ∘ LinearMap(RotY(t/10) * RotX(sqrt(2)*t/10) * RotZ(pi*t/10)) ∘ Translation(-0.5, -0.5, -0.5)).(cube.vertices)

    flip!(board, draw_wireframe(cube, camera_transform, BOARD_SIZE))
    notify(board) 

    t += 0.1
end
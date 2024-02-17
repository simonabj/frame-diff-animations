using GLMakie
using CoordinateTransformations

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

camera_pos = [0, 0, -2]
camera_transform = PerspectiveMap() ∘ inv(AffineMap(I, camera_pos))

my_cube = UnitCube()

my_cube.vertices = Translation(0, 0, 4).(my_cube.vertices)

flip!(board, draw_wireframe(my_cube, camera_transform, BOARD_SIZE))

fig, ax, img = draw(board)

camera_sliders = SliderGrid(
    fig[2,1],
    (label = "X", range=-3:0.1:3, startvalue=0),
    (label = "Y", range=-3:0.1:3, startvalue=0),
    (label = "Z", range=-10:0.01:10, startvalue=1)
)

camera_slider_observables = [s.value for s in camera_sliders.sliders]

camera_node = lift(camera_slider_observables...) do vals...
    global camera_pos = [vals...]
end


on(camera_node) do new_cam
    cube = UnitCube()

    camera_transform = PerspectiveMap() ∘ inv(AffineMap(I, camera_pos))
    cube.vertices = Translation(0, 0, 4).(cube.vertices)

    flip!(board, draw_wireframe(cube, camera_transform, BOARD_SIZE))
    notify(board)
end



fig
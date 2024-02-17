using LinearAlgebra;

struct Pixel
    x::Int
    y::Int
end

Base.getindex(p::Pixel, i::Int) = i == 1 ? p.x : p.y
convert(::Type{Pixel}, p::Vector{Float64}) = Pixel(floor(Int, p[1]), floor(Int, p[2]))

mutable struct Camera
    position::Vector{Float64}
    u::Vector{Float64}
    v::Vector{Float64}
    w::Vector{Float64}

    function Camera(position::Vector{Float64}, lookat::Vector{Float64}, up::Vector{Float64})
        u = normalize(cross(up, position - lookat))
        v = normalize(cross(position - lookat, u))
        w = normalize(lookat - position)
        new(position, u, v, w)
    end
end

function DefaultCamera()
    return Camera([0.0, 0, 0], [0.0, 0, 1], [0.0, 1, 0])
end

mutable struct ViewFrustum 
    near_plane::Float64
    far_plane::Float64
    fov::Float64
    aspect::Float64
end

DefaultFrustum() = ViewFrustum(10.0, 1000.0, π/2, 16/9)

"""
    ViewTransform(camera::Camera)

Creates a view transformation matrix from a camera object. The 
view transformation matrix is used to transform the world space
coordinates into view space coordinates. 
"""
function ViewTransform(camera::Camera)
    # Camera translation
    T = [
        1 0 0 -camera.position[1];
        0 1 0 -camera.position[2];
        0 0 1 -camera.position[3];
        0 0 0 1
    ]
    M = [ [camera.u camera.v camera.w zeros(3)] ; 
          [   0        0        0         1   ] ]

    return M * T
end


"""
    ProjectionMatrix(frustum::ViewFrustum)

Creates a projection matrix from a view frustum. The projection transform
points from view space to NDC space (Normalized Device Coordinates) which
is a cube with sides of length 2 and centered at the origin. When given a
frustum, the resulting transform will appear as a perspective projection.
"""
function ProjectionTransform(frustum::ViewFrustum)
    n = -frustum.near_plane
    f = -frustum.far_plane
    a = frustum.aspect
    t = tan(frustum.fov / 2)
    return [
       1/(a*t) 0 0 0;
       0 1/t 0 0;
       0 0 -(f+n)/(f-n) -2*f*n/(f-n);
       0 0 -1 0
    ]
end


"""
    ViewportTransformation(width::Int, height::Int)

Creates a viewport transformation matrix from the width and height of the
viewport. The viewport transformation maps the NDC space to screen space
by linear interpolation of the NDC coordinates to the screen space coordinates.

The canonical view volume is mapped to the screen that has n_x x n_y pixels, such
that a points at x=-1 and x=1 are mapped to the left and right edges of the screen,
and similar for the y axis.

2D images cannot display the z axis, so the z-component is discarded.
"""
function ViewportTransform(width::Int, height::Int)
    return [
        width/2 0 0 (width-1)/2;
        0 height/2 0 (height-1)/2;
        0 0 1 0;
        0 0 0 1
    ]
end
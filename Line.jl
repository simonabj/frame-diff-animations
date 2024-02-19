function _line_high(p1, p2)
    dx = p2[1] - p1[1]
    dy = p2[2] - p1[2]
    
    xi = 1
    if dx < 0
        xi = -1
        dx = -dx
    end

    D = 2 * dx - dy
    x = p1[1]

    points = []
    for y in p1[2]:p2[2]
        push!(points, (x, y))
        if D > 0
            x += xi
            D += 2 * (dx - dy)
        else
            D += 2 * dx
        end
    end

    return points
end

function _line_low(p1, p2)
    dx = p2[1] - p1[1]
    dy = p2[2] - p1[2]

    yi = 1
    if dy < 0
        yi = -1
        dy = -dy
    end

    D = 2 * dy - dx
    y = p1[2]

    points = []
    for x in p1[1]:p2[1]
        push!(points, (x, y))
        if D > 0
            y += yi
            D += 2 * (dy - dx)
        else
            D += 2 * dy
        end
    end

    return points
end

function get_line(p1, p2)
    if abs(p2[2] - p1[2]) < abs(p2[1] - p1[1])
        if p1[1] > p2[1]
            return _line_low(p2, p1)
        else
            return _line_low(p1, p2)
        end
    else
        if p1[2] > p2[2]
            return _line_high(p2, p1)
        else
            return _line_high(p1, p2)
        end
    end
end

function draw_wireframe(wireframe::Wireframe, camera::Camera, frustum::ViewFrustum, screen_size::Tuple{Int, Int})
    view_transform = ViewTransform(camera)
    projection_matrix = ProjectionTransform(frustum)
    viewport_matrix = ViewportTransform(screen_size...)

    model_view_projection = viewport_matrix * projection_matrix * view_transform


    points = []
    for edge in wireframe.edges
        p1 = convert(Pixel, model_view_projection * wireframe.vertices[edge[1]])
        p2 = convert(Pixel, model_view_projection * wireframe.vertices[edge[2]])
        push!.(Ref(points), get_line(p1, p2))
    end

    return points
end

function draw_wireframe(wireframe::Wireframe, camera_transform::CoordinateTransformations.ComposedTransformation, screen_size::Tuple{Int, Int})
    
    screen_transform = LinearMap([ 
        screen_size[1]          0 ; 
             0          screen_size[2] 
    ])
    transformed_vertices = map(screen_transform ∘ camera_transform, wireframe.vertices)

    # print(transformed_vertices)

    points = []
    for edge in wireframe.edges
        p1 = convert(Pixel, transformed_vertices[edge[1]])
        p2 = convert(Pixel, transformed_vertices[edge[2]])
        push!.(Ref(points), get_line(p1, p2))
    end

    return points
end
function gpugradtest(m, fg, x::AbstractArray{T}) where T
    m_gpu = m |> gpu
    fg_gpu = fg |> gpu
    x_gpu = x |> gpu
    ps = Flux.params(m)
    ps_gpu = Flux.params(m_gpu)

    # output
    y = m(fg, x)
    y_gpu = m_gpu(fg_gpu, x_gpu)
    @test y_gpu isa CuArray{T}
    @test Array(y_gpu) ≈ y

    # input gradient
    gs = gradient(x -> sum(m(fg, x)), x)[1]
    gs_gpu = gradient(x_gpu -> sum(m_gpu(fg_gpu, x_gpu)), x_gpu)[1]
    @test gs_gpu isa CuArray{T}
    @test Array(gs_gpu) ≈ gs

    # model gradient
    gs = gradient(() -> sum(m(fg, x)), Flux.params(m))
    gs_gpu = gradient(() -> sum(m_gpu(fg_gpu, x_gpu)), Flux.params(m_gpu))
    for (p, p_gpu) in zip(ps, ps_gpu)
        if gs[p] == nothing
            @test gs_gpu[p_gpu] == nothing            
        else
            @test gs_gpu[p_gpu] isa CuArray{T}
            @test Array(gs_gpu[p_gpu]) ≈ gs[p]
        end
    end
    return true
end

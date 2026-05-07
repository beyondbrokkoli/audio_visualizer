local ffi = require("ffi")

local Descriptors = {}

function Descriptors.Init(vk, device, bufCPU_A, bufCPU_B, bufPing, bufPong)
    print("[DESCRIPTORS] Wiring Asynchronous Tandem Rendering Sets...")

    -- ========================================================
    -- 1. The Descriptor Set Layout (0=Read CPU, 1=Write GPU, 2=Read GPU Past)
    -- ========================================================
    local ssboBindings = ffi.new("VkDescriptorSetLayoutBinding[3]") -- INCREASED TO 3
    ffi.fill(ssboBindings, ffi.sizeof(ssboBindings))

    ssboBindings[0].binding = 0
    ssboBindings[0].descriptorType = 7 -- VK_DESCRIPTOR_TYPE_STORAGE_BUFFER
    ssboBindings[0].descriptorCount = 1
    ssboBindings[0].stageFlags = 32 -- VK_SHADER_STAGE_COMPUTE_BIT

    ssboBindings[1].binding = 1
    ssboBindings[1].descriptorType = 7
    ssboBindings[1].descriptorCount = 1
    ssboBindings[1].stageFlags = 32

    ssboBindings[2].binding = 2                     -- NEW: GPU Past Input
    ssboBindings[2].descriptorType = 7
    ssboBindings[2].descriptorCount = 1
    ssboBindings[2].stageFlags = 32

    local layoutInfo = ffi.new("VkDescriptorSetLayoutCreateInfo")
    ffi.fill(layoutInfo, ffi.sizeof(layoutInfo))
    layoutInfo.sType = 32 -- VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO
    layoutInfo.bindingCount = 3                     -- UPDATED
    layoutInfo.pBindings = ssboBindings

    local pLayout = ffi.new("VkDescriptorSetLayout[1]")
    assert(vk.vkCreateDescriptorSetLayout(device, layoutInfo, nil, pLayout) == 0)
    local computeDescriptorSetLayout = pLayout[0]

    -- ========================================================
    -- 2. Push Constants (20 BYTES for Simulation State & Interaction)
    -- ========================================================
    local computePushRange = ffi.new("VkPushConstantRange[1]")
    ffi.fill(computePushRange, ffi.sizeof(computePushRange))
    computePushRange[0].stageFlags = 32 -- VK_SHADER_STAGE_COMPUTE_BIT
    computePushRange[0].offset = 0
    computePushRange[0].size = 32 -- sizeof(float)*5 + sizeof(int)*3

    -- ========================================================
    -- 3. Pipeline Layout
    -- ========================================================
    local computeLayoutInfo = ffi.new("VkPipelineLayoutCreateInfo")
    ffi.fill(computeLayoutInfo, ffi.sizeof(computeLayoutInfo))
    computeLayoutInfo.sType = 30 -- VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO
    computeLayoutInfo.setLayoutCount = 1

    local pSetLayouts = ffi.new("VkDescriptorSetLayout[1]", {computeDescriptorSetLayout})
    computeLayoutInfo.pSetLayouts = pSetLayouts
    computeLayoutInfo.pushConstantRangeCount = 1
    computeLayoutInfo.pPushConstantRanges = computePushRange

    local pPipeLayout = ffi.new("VkPipelineLayout[1]")
    assert(vk.vkCreatePipelineLayout(device, computeLayoutInfo, nil, pPipeLayout) == 0)
    local computePipelineLayout = pPipeLayout[0]

    -- ========================================================
    -- 4. Descriptor Pool
    -- ========================================================
    local poolSize = ffi.new("VkDescriptorPoolSize[1]")
    ffi.fill(poolSize, ffi.sizeof(poolSize))
    poolSize[0].type = 7 -- VK_DESCRIPTOR_TYPE_STORAGE_BUFFER
    poolSize[0].descriptorCount = 6                 -- UPDATED: 3 Bindings * 2 Sets = 6

    local poolInfo = ffi.new("VkDescriptorPoolCreateInfo")
    ffi.fill(poolInfo, ffi.sizeof(poolInfo))
    poolInfo.sType = 33 -- VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO
    poolInfo.poolSizeCount = 1
    poolInfo.pPoolSizes = poolSize
    poolInfo.maxSets = 2 -- Two Sets

    local pPool = ffi.new("VkDescriptorPool[1]")
    assert(vk.vkCreateDescriptorPool(device, poolInfo, nil, pPool) == 0)
    local descriptorPool = pPool[0]

    -- ========================================================
    -- 5. Allocate TWO Descriptor Sets
    -- ========================================================
    local layouts = ffi.new("VkDescriptorSetLayout[2]", {computeDescriptorSetLayout, computeDescriptorSetLayout})
    local allocSetInfo = ffi.new("VkDescriptorSetAllocateInfo")
    ffi.fill(allocSetInfo, ffi.sizeof(allocSetInfo))
    allocSetInfo.sType = 34 -- VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO
    allocSetInfo.descriptorPool = descriptorPool
    allocSetInfo.descriptorSetCount = 2
    allocSetInfo.pSetLayouts = layouts

    local pSets = ffi.new("VkDescriptorSet[2]")
    assert(vk.vkAllocateDescriptorSets(device, allocSetInfo, pSets) == 0)

    -- ========================================================
    -- 6. Cross-Wire the 4-Field Phasing Matrix
    -- ========================================================
    local VK_WHOLE_SIZE = ffi.cast("uint64_t", -1)

    local bufInfoCPU_A = ffi.new("VkDescriptorBufferInfo[1]")
    bufInfoCPU_A[0].buffer = bufCPU_A
    bufInfoCPU_A[0].offset = 0
    bufInfoCPU_A[0].range = VK_WHOLE_SIZE

    local bufInfoCPU_B = ffi.new("VkDescriptorBufferInfo[1]")
    bufInfoCPU_B[0].buffer = bufCPU_B
    bufInfoCPU_B[0].offset = 0
    bufInfoCPU_B[0].range = VK_WHOLE_SIZE

    local bufInfoPing = ffi.new("VkDescriptorBufferInfo[1]")
    bufInfoPing[0].buffer = bufPing
    bufInfoPing[0].offset = 0
    bufInfoPing[0].range = VK_WHOLE_SIZE

    local bufInfoPong = ffi.new("VkDescriptorBufferInfo[1]")
    bufInfoPong[0].buffer = bufPong
    bufInfoPong[0].offset = 0
    bufInfoPong[0].range = VK_WHOLE_SIZE

    local writes = ffi.new("VkWriteDescriptorSet[6]") -- INCREASED TO 6
    ffi.fill(writes, ffi.sizeof(writes))

    -- Set 0 (Even Frames): Compute reads CPU_A (0), Writes Ping (1), Reads Pong (2)
    writes[0].sType = 35; writes[0].dstSet = pSets[0]; writes[0].dstBinding = 0
    writes[0].descriptorType = 7; writes[0].descriptorCount = 1; writes[0].pBufferInfo = bufInfoCPU_A

    writes[1].sType = 35; writes[1].dstSet = pSets[0]; writes[1].dstBinding = 1
    writes[1].descriptorType = 7; writes[1].descriptorCount = 1; writes[1].pBufferInfo = bufInfoPing

    writes[2].sType = 35; writes[2].dstSet = pSets[0]; writes[2].dstBinding = 2
    writes[2].descriptorType = 7; writes[2].descriptorCount = 1; writes[2].pBufferInfo = bufInfoPong

    -- Set 1 (Odd Frames): Compute reads CPU_B (0), Writes Pong (1), Reads Ping (2)
    writes[3].sType = 35; writes[3].dstSet = pSets[1]; writes[3].dstBinding = 0
    writes[3].descriptorType = 7; writes[3].descriptorCount = 1; writes[3].pBufferInfo = bufInfoCPU_B

    writes[4].sType = 35; writes[4].dstSet = pSets[1]; writes[4].dstBinding = 1
    writes[4].descriptorType = 7; writes[4].descriptorCount = 1; writes[4].pBufferInfo = bufInfoPong

    writes[5].sType = 35; writes[5].dstSet = pSets[1]; writes[5].dstBinding = 2
    writes[5].descriptorType = 7; writes[5].descriptorCount = 1; writes[5].pBufferInfo = bufInfoPing

    vk.vkUpdateDescriptorSets(device, 6, writes, 0, nil) -- UPDATED COUNT TO 6

    print("[DESCRIPTORS] Asynchronous Tandem Rendering Sets successfully wired!")

    return {
        setLayout = computeDescriptorSetLayout,
        pipelineLayout = computePipelineLayout,
        pool = descriptorPool,
        set0 = pSets[0],
        set1 = pSets[1]
    }
end

function Descriptors.Destroy(vk, device, desc_state)
    print("[TEARDOWN] Deconstructing Descriptors...")
    if not desc_state then return end

    if desc_state.pool ~= nil then vk.vkDestroyDescriptorPool(device, desc_state.pool, nil) end
    if desc_state.setLayout ~= nil then vk.vkDestroyDescriptorSetLayout(device, desc_state.setLayout, nil) end
    if desc_state.pipelineLayout ~= nil then vk.vkDestroyPipelineLayout(device, desc_state.pipelineLayout, nil) end
end

return Descriptors

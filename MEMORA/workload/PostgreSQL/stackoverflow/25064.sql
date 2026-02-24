
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  
        AND p.Score > 0   
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalQuestions,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(DISTINCT p.Id) > 5  
),
TaggedPosts AS (
    SELECT 
        u.Id AS UserId,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    JOIN 
        Users u ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
)
SELECT 
    tu.DisplayName,
    tu.TotalQuestions,
    tu.TotalScore,
    rp.Title AS TopPostTitle,
    rp.Tags AS PostTags,
    rp.CreationDate AS PostCreationDate,
    tp.Tags AS UserTags
FROM 
    TopUsers tu
JOIN 
    RankedPosts rp ON tu.UserId = rp.OwnerUserId AND rp.RankByScore = 1  
LEFT JOIN 
    TaggedPosts tp ON tu.UserId = tp.UserId
ORDER BY 
    tu.TotalScore DESC, tu.TotalQuestions DESC;

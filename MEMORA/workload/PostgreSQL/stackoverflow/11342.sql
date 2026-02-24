WITH UserPostCounts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
), 
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount
    FROM 
        UserPostCounts
    ORDER BY 
        PostCount DESC
    LIMIT 10
), 
PostScores AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        u.DisplayName AS OwnerDisplayName
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.Score IS NOT NULL
)
SELECT 
    tu.DisplayName AS TopUser,
    tu.PostCount,
    ps.PostId,
    ps.Title,
    ps.Score
FROM 
    TopUsers tu
JOIN 
    PostScores ps ON ps.OwnerDisplayName = tu.DisplayName
ORDER BY 
    tu.PostCount DESC, ps.Score DESC;
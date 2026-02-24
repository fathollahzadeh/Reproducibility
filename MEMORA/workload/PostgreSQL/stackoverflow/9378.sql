
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
        AND p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, u.DisplayName, p.OwnerUserId
),
TopUsers AS (
    SELECT 
        OwnerUserId,
        COUNT(Id) AS TotalPosts,
        SUM(Score) AS TotalScore
    FROM 
        RankedPosts
    WHERE 
        PostRank <= 5
    GROUP BY 
        OwnerUserId
)
SELECT 
    u.DisplayName,
    tu.TotalPosts,
    tu.TotalScore,
    ROW_NUMBER() OVER (ORDER BY tu.TotalScore DESC) AS UserRank
FROM 
    TopUsers tu
JOIN 
    Users u ON tu.OwnerUserId = u.Id
ORDER BY 
    tu.TotalScore DESC, tu.TotalPosts DESC;

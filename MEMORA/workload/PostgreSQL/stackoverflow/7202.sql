WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year' 
        AND p.PostTypeId IN (1, 2) 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId, u.DisplayName
),
TopUsers AS (
    SELECT 
        OwnerUserId,
        COUNT(PostId) AS TotalPosts,
        SUM(Score) AS TotalScore
    FROM 
        RankedPosts
    WHERE 
        PostRank <= 10 
    GROUP BY 
        OwnerUserId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    tu.TotalPosts,
    tu.TotalScore,
    AVG(rp.Score) AS AvgPostScore,
    COUNT(DISTINCT rp.PostId) AS PostsWithComments
FROM 
    Users u
JOIN 
    TopUsers tu ON u.Id = tu.OwnerUserId
LEFT JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId
GROUP BY 
    u.Id, u.DisplayName, tu.TotalPosts, tu.TotalScore
ORDER BY 
    tu.TotalScore DESC, tu.TotalPosts DESC
LIMIT 100;
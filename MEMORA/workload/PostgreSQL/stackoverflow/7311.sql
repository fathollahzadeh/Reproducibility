WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        u.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopUsers AS (
    SELECT 
        OwnerDisplayName,
        COUNT(PostId) AS TotalPosts
    FROM 
        RankedPosts
    WHERE 
        PostRank <= 5
    GROUP BY 
        OwnerDisplayName
)
SELECT 
    u.DisplayName AS User,
    u.Reputation,
    u.CreationDate,
    tu.TotalPosts,
    (SELECT COUNT(*) FROM Badges b WHERE b.UserId = u.Id) AS BadgeCount
FROM 
    Users u
JOIN 
    TopUsers tu ON u.DisplayName = tu.OwnerDisplayName
WHERE 
    u.Reputation > 1000
ORDER BY 
    tu.TotalPosts DESC, u.Reputation DESC;
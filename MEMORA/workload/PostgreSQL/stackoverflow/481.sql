WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation,
        AVG(p.Score) AS AvgScore
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
    HAVING 
        AVG(p.Score) > 10
)
SELECT 
    tu.UserId,
    tu.DisplayName,
    tu.Reputation,
    rp.Title AS LatestPostTitle,
    rp.CreationDate AS LatestPostDate,
    rp.CommentCount AS LatestPostComments,
    COALESCE(b.Name, 'No Badge') AS BadgeName
FROM 
    TopUsers tu
LEFT JOIN 
    RankedPosts rp ON tu.UserId = rp.OwnerUserId AND rp.PostRank = 1
LEFT JOIN 
    Badges b ON tu.UserId = b.UserId
WHERE 
    (b.Class = 1 OR b.Class = 2 OR b.Class IS NULL)
ORDER BY 
    tu.Reputation DESC, 
    rp.CreationDate DESC;
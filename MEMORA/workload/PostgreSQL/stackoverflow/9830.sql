WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.ViewCount, 
        p.Score, 
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
        AND p.ViewCount > 100
),
TopPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.ViewCount, 
        rp.Score 
    FROM 
        RankedPosts rp 
    WHERE 
        rp.Rank <= 5
),
UserPostCounts AS (
    SELECT 
        u.Id AS UserId, 
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.Score <= 0 THEN 1 ELSE 0 END) AS NegativePosts
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
)
SELECT 
    u.DisplayName,
    u.Reputation,
    up.PostCount,
    up.PositivePosts,
    up.NegativePosts,
    tp.Title AS TopPostTitle,
    tp.ViewCount,
    tp.Score
FROM 
    Users u
JOIN 
    UserPostCounts up ON u.Id = up.UserId
LEFT JOIN 
    TopPosts tp ON up.PostCount > 0
ORDER BY 
    u.Reputation DESC, 
    up.PostCount DESC;
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate > '2023-01-01' AND p.PostTypeId IN (1, 2) 
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerUserId,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.TagRank <= 5 
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        COUNT(b.Id) AS BadgesCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
UserPostDetails AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        tp.PostId,
        tp.Title,
        tp.CreationDate,
        tp.Score,
        tp.ViewCount
    FROM 
        TopPosts tp
    JOIN 
        UserStats us ON tp.OwnerUserId = us.UserId
)
SELECT 
    upd.UserId,
    upd.DisplayName,
    COUNT(upd.PostId) AS UserPostCount,
    SUM(upd.ViewCount) AS TotalViews,
    AVG(upd.Score) AS AverageScore,
    us.PostsCount,
    us.PositivePosts,
    us.NegativePosts,
    us.BadgesCount
FROM 
    UserPostDetails upd
JOIN 
    UserStats us ON upd.UserId = us.UserId
GROUP BY 
    upd.UserId, upd.DisplayName, us.PostsCount, us.PositivePosts, us.NegativePosts, us.BadgesCount
ORDER BY 
    TotalViews DESC 
LIMIT 100;
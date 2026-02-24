
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS RankScore,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId, u.DisplayName, p.CreationDate, p.Score, p.ViewCount
),
TopRankedPosts AS (
    SELECT 
        PostId,
        Title,
        OwnerUserId,
        OwnerDisplayName,
        CreationDate,
        Score,
        ViewCount,
        CommentCount
    FROM 
        RankedPosts
    WHERE 
        RankScore <= 3
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    trp.Title,
    trp.OwnerDisplayName,
    trp.CreationDate,
    trp.Score,
    trp.ViewCount,
    trp.CommentCount,
    ub.BadgeCount
FROM 
    TopRankedPosts trp
JOIN 
    UserBadges ub ON trp.OwnerUserId = ub.UserId
ORDER BY 
    trp.Score DESC, trp.CreationDate DESC;

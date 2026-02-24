WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerName,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS RankScore
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopRankedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerName,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankScore <= 10
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
PostBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    trp.PostId,
    trp.Title,
    trp.OwnerName,
    trp.CreationDate,
    trp.Score,
    trp.ViewCount,
    COALESCE(pc.CommentCount, 0) AS TotalComments,
    COALESCE(pb.BadgeCount, 0) AS OwnerBadgeCount
FROM 
    TopRankedPosts trp
LEFT JOIN 
    PostComments pc ON trp.PostId = pc.PostId
LEFT JOIN 
    Users u ON trp.OwnerName = u.DisplayName
LEFT JOIN 
    PostBadges pb ON u.Id = pb.UserId
ORDER BY 
    trp.Score DESC, trp.ViewCount DESC;
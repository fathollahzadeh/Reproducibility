WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND 
        p.Score > 0
), TopRankedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerUserId,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.Score
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
), PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
), PostBadges AS (
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
    trp.OwnerDisplayName,
    trp.CreationDate,
    trp.Score,
    pc.CommentCount,
    pb.BadgeCount
FROM 
    TopRankedPosts trp
LEFT JOIN 
    PostComments pc ON trp.PostId = pc.PostId
LEFT JOIN 
    PostBadges pb ON trp.OwnerUserId = pb.UserId
ORDER BY 
    trp.Score DESC, trp.CreationDate DESC;

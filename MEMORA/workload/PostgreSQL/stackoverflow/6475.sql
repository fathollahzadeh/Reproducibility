WITH RankedPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.Score, 
        p.CreationDate, 
        u.DisplayName AS OwnerDisplayName, 
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
PostComments AS (
    SELECT 
        pc.PostId, 
        COUNT(*) AS CommentCount 
    FROM 
        Comments pc
    GROUP BY 
        pc.PostId
),
PostBadges AS (
    SELECT 
        b.UserId, 
        COUNT(*) AS BadgeCount 
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    rp.Id, 
    rp.Title, 
    rp.Score, 
    rp.CreationDate, 
    rp.OwnerDisplayName, 
    COALESCE(pc.CommentCount, 0) AS CommentCount, 
    COALESCE(pb.BadgeCount, 0) AS BadgeCount
FROM 
    RankedPosts rp
LEFT JOIN 
    PostComments pc ON rp.Id = pc.PostId
LEFT JOIN 
    PostBadges pb ON rp.Id = pb.UserId
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.Score DESC;

WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        p.OwnerUserId
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.ViewCount > 1000
), 
PostComments AS (
    SELECT 
        pc.PostId,
        COUNT(pc.Id) AS CommentCount,
        STRING_AGG(pc.Text, '; ') AS Comments
    FROM 
        Comments pc
    GROUP BY 
        pc.PostId
), 
PostsWithBadges AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        COALESCE(b.BadgeCount, 0) AS BadgeCount,
        rp.OwnerUserId
    FROM 
        RankedPosts rp
    LEFT JOIN 
        (SELECT 
            UserId, 
            COUNT(Id) AS BadgeCount 
         FROM 
            Badges 
         WHERE 
            Class = 1 /* Gold badges */
         GROUP BY 
            UserId) b ON rp.OwnerUserId = b.UserId
), 
FinalResults AS (
    SELECT 
        pwb.Title,
        pwb.ViewCount,
        pwb.Score,
        pwb.BadgeCount,
        pc.CommentCount,
        pc.Comments,
        pwb.CreationDate
    FROM 
        PostsWithBadges pwb
    LEFT JOIN 
        PostComments pc ON pwb.PostId = pc.PostId
)
SELECT 
    f.Title,
    f.ViewCount,
    f.Score,
    f.BadgeCount,
    f.CommentCount,
    f.Comments,
    DENSE_RANK() OVER (ORDER BY f.Score DESC, f.ViewCount DESC) AS RankScore
FROM 
    FinalResults f
WHERE 
    f.BadgeCount > 0 OR f.CommentCount > 5
ORDER BY 
    RankScore,
    f.CreationDate DESC
LIMIT 100;

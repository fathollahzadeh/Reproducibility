
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),

PostWithBadges AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Tags,
        rp.CreationDate,
        rp.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(b.Id) AS BadgeCount
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        rp.PostId, rp.Title, rp.Tags, rp.CreationDate, rp.Score, u.DisplayName
),

TopRankedPosts AS (
    SELECT 
        pwb.PostId,
        pwb.Title,
        pwb.Tags,
        pwb.CreationDate,
        pwb.Score,
        pwb.OwnerDisplayName,
        pwb.BadgeCount,
        RANK() OVER (ORDER BY pwb.Score DESC) AS ScoreRank
    FROM 
        PostWithBadges pwb
)

SELECT 
    trp.PostId,
    trp.Title,
    trp.Tags,
    trp.CreationDate,
    trp.Score,
    trp.OwnerDisplayName,
    trp.BadgeCount
FROM 
    TopRankedPosts trp
WHERE 
    trp.ScoreRank <= 10 
    AND trp.BadgeCount > 0 
ORDER BY 
    trp.Score DESC;

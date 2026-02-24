
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.Body,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS Badges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
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
CombinedData AS (
    SELECT 
        r.PostId,
        r.Title,
        r.Score,
        r.ViewCount,
        r.CreationDate,
        r.Body,
        r.OwnerUserId,
        r.OwnerDisplayName,
        COALESCE(ub.BadgeCount, 0) AS BadgeCount,
        COALESCE(ub.Badges, 'No Badges') AS Badges,
        COALESCE(pc.CommentCount, 0) AS CommentCount,
        r.PostRank
    FROM 
        RankedPosts r
    LEFT JOIN 
        UserBadges ub ON r.OwnerUserId = ub.UserId
    LEFT JOIN 
        PostComments pc ON r.PostId = pc.PostId
)
SELECT 
    CD.PostId,
    CD.Title,
    CD.Score,
    CD.ViewCount,
    CD.CreationDate,
    CD.Body,
    CD.OwnerDisplayName,
    CD.BadgeCount,
    CD.Badges,
    CD.CommentCount
FROM 
    CombinedData CD
WHERE 
    CD.PostRank <= 3 
ORDER BY 
    CD.OwnerDisplayName, CD.CreationDate DESC;

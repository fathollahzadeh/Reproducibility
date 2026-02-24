
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.CreationDate DESC) AS Rank,
        COALESCE(NULLIF(u.Location, ''), 'Unknown Location') AS UserLocation
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
        AND p.Score > (SELECT AVG(Score) FROM Posts)  
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(*) AS CommentCount,
        STRING_AGG(c.Text, '; ' ORDER BY c.CreationDate) AS CommentsSummary
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS Badges 
    FROM 
        Badges b
    WHERE 
        b.Class = 1  
    GROUP BY 
        b.UserId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    COALESCE(pc.CommentCount, 0) AS NumberOfComments,
    COALESCE(pc.CommentsSummary, 'No comments') AS CommentSnippet,
    ub.BadgeCount,
    ub.Badges,
    rp.UserLocation
FROM 
    RankedPosts rp
LEFT JOIN 
    PostComments pc ON rp.PostId = pc.PostId
LEFT JOIN 
    UserBadges ub ON rp.UserLocation IS NOT NULL AND rp.UserLocation <> 'Unknown Location' 
                  AND EXISTS (SELECT 1 FROM Users u WHERE u.Id = ub.UserId AND COALESCE(u.Location, '') = rp.UserLocation)
WHERE 
    (rp.Rank <= 5 OR ub.BadgeCount > 0)  
ORDER BY 
    rp.Score DESC, rp.CreationDate ASC
OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY;

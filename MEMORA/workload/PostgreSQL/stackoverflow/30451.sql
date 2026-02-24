
WITH RECURSIVE UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        COALESCE(MAX(c.CreationDate), CAST('2000-01-01' AS TIMESTAMP)) AS LatestCommentDate,
        COUNT(DISTINCT ppm.UserId) AS UniqueCommenters
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        (SELECT DISTINCT 
             PostId, UserId 
         FROM 
             Comments) ppm ON ppm.PostId = p.Id
    WHERE 
        p.CreationDate > CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year' 
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.ViewCount
),
RankedPostDetails AS (
    SELECT 
        pd.*,
        RANK() OVER (ORDER BY pd.Score DESC, pd.ViewCount DESC) AS PostRank
    FROM 
        PostDetails pd
),
FinalResults AS (
    SELECT 
        rpd.Title,
        rpd.Score,
        rpd.ViewCount,
        rpd.LatestCommentDate,
        ubc.BadgeCount,
        rpd.PostRank
    FROM 
        RankedPostDetails rpd
    JOIN 
        UserBadgeCounts ubc ON rpd.PostId = (SELECT p.Id 
                                              FROM Posts p 
                                              WHERE p.OwnerUserId = ubc.UserId 
                                              ORDER BY p.Score DESC 
                                              LIMIT 1)
    WHERE 
        rpd.LatestCommentDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days' 
)
SELECT 
    Title,
    Score,
    ViewCount,
    LatestCommentDate,
    BadgeCount,
    PostRank
FROM 
    FinalResults
ORDER BY 
    PostRank
LIMIT 10;

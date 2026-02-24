
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(pc.Id) AS CommentCount,
        AVG(u.Reputation) AS AvgReputation
    FROM 
        Posts p
    LEFT JOIN 
        Comments pc ON p.Id = pc.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.CreationDate, p.Score, p.PostTypeId
),
TopRankedPosts AS (
    SELECT 
        PostId,
        Title,
        ViewCount,
        CreationDate,
        Score,
        Rank,
        CommentCount,
        AvgReputation
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
),
TotalViews AS (
    SELECT 
        SUM(ViewCount) AS TotalViewCount,
        COUNT(DISTINCT PostId) AS UniquePostCount
    FROM 
        TopRankedPosts
),
MaxScore AS (
    SELECT 
        MAX(Score) AS HighestScore
    FROM 
        Posts
),
NotableBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges b
    WHERE 
        b.Class = 1
    GROUP BY 
        b.UserId
)
SELECT 
    T.PostId,
    T.Title,
    T.ViewCount,
    COALESCE(V.TotalViewCount, 0) AS OverallViews,
    T.CreationDate,
    T.Score,
    T.CommentCount,
    T.AvgReputation,
    B.BadgeCount,
    CASE 
        WHEN T.Score = M.HighestScore THEN 'Top Scorer'
        ELSE CASE 
            WHEN T.CommentCount = 0 THEN 'No Comments'
            ELSE 'Engaged'
        END
    END AS EngagementLevel
FROM 
    TopRankedPosts T
LEFT JOIN 
    TotalViews V ON TRUE
LEFT JOIN 
    MaxScore M ON TRUE
LEFT JOIN 
    NotableBadges B ON T.PostId = B.UserId
WHERE 
    (T.ViewCount IS NOT NULL OR T.CommentCount IS NOT NULL)
    AND (T.ViewCount + COALESCE(T.CommentCount, 0)) > 10
ORDER BY 
    T.Score DESC, T.ViewCount DESC;

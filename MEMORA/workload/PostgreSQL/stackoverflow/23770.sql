
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        ARRAY_AGG(t.TagName) AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON t.ExcerptPostId = p.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
        AND p.ViewCount IS NOT NULL 
        AND p.Score IS NOT NULL
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
PostStats AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        Tags,
        CASE 
            WHEN Score > 10 THEN 'High Score'
            WHEN Score BETWEEN 5 AND 10 THEN 'Medium Score'
            ELSE 'Low Score' 
        END AS ScoreCategory
    FROM 
        RankedPosts
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS TotalBadges,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    GROUP BY 
        u.Id
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        COALESCE(ph.Comment, 'No Comment') AS HistoryComment,
        CASE 
            WHEN ph.PostHistoryTypeId IN (10, 11) THEN 'Closed/Reopened'
            ELSE 'Other'
        END AS ActionType
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '6 months'
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.Tags,
    ps.ScoreCategory,
    COALESCE(ub.BadgeNames, 'No Badges') AS BadgeNames,
    COALESCE(ub.TotalBadges, 0) AS TotalBadges,
    COALESCE(phd.HistoryComment, 'No History') AS LastActionComment,
    phd.ActionType
FROM 
    PostStats ps
LEFT JOIN 
    UserBadges ub ON ub.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = ps.PostId)
LEFT JOIN 
    PostHistoryDetails phd ON phd.PostId = ps.PostId
WHERE 
    (ps.ScoreCategory = 'High Score' OR ub.TotalBadges > 5)
    AND EXISTS (
        SELECT 1 
        FROM Votes v 
        WHERE v.PostId = ps.PostId AND v.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 month'
        GROUP BY v.PostId 
        HAVING COUNT(v.Id) >= 3
    )
ORDER BY 
    ps.CreationDate DESC, 
    ps.Score DESC
LIMIT 100;

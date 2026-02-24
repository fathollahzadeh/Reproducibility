
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AcceptedAnswerId,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COALESCE(NULLIF(u.Reputation, 0), -1) AS EffectiveReputation
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id 
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
BadgesWithCounts AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        STRING_AGG(CONCAT(ph.Comment, ': ', ph.CreationDate::TEXT), ' | ') AS HistoryComments,
        COUNT(ph.Id) AS HistoryCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.OwnerDisplayName,
    COALESCE(bc.BadgeCount, 0) AS TotalBadges,
    COALESCE(bc.BadgeNames, 'No Badges') AS BadgeNames,
    COALESCE(phs.HistoryCount, 0) AS TotalHistory,
    COALESCE(phs.HistoryComments, 'No History') AS HistoryDetails,
    CASE 
        WHEN rp.Score IS NULL THEN 'No score'
        WHEN rp.Score > 100 THEN 'High Score'
        WHEN rp.Score BETWEEN 50 AND 100 THEN 'Medium Score'
        ELSE 'Low Score'
    END AS ScoreCategory,
    CASE 
        WHEN rp.ViewCount IS NULL THEN 'No views'
        WHEN rp.ViewCount < 10 THEN 'Low views'
        ELSE 'Popular'
    END AS ViewCategory
FROM 
    RankedPosts rp
LEFT JOIN 
    BadgesWithCounts bc ON rp.PostId = bc.UserId
LEFT JOIN 
    PostHistorySummary phs ON rp.PostId = phs.PostId
WHERE 
    rp.rn = 1 
    AND rp.EffectiveReputation IS NOT NULL
ORDER BY 
    rp.ViewCount DESC, 
    rp.Score DESC
OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY;

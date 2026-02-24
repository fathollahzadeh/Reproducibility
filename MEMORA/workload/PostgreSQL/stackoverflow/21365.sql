WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        COALESCE(ph.Comment, 'No close reason applicable') AS CloseReason,
        ROW_NUMBER() OVER(PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS ViewRank,
        RANK() OVER (ORDER BY p.CreationDate DESC) AS RecentRank,
        DENSE_RANK() OVER (ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10
    WHERE 
        p.CreationDate > '2020-01-01' 
        AND (p.ViewCount > 100 OR ph.Comment IS NOT NULL)
),
AggregatedData AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(b.Id) AS BadgeCount,
        AVG(CASE WHEN p.Score IS NOT NULL THEN p.Score ELSE 0 END) AS AvgScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 100
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    a.UserId,
    a.DisplayName,
    a.TotalViews,
    a.PostCount,
    a.BadgeCount,
    a.AvgScore,
    r.PostId,
    r.Title,
    r.ViewCount,
    r.CloseReason,
    CASE 
        WHEN r.ViewRank IS NULL THEN 'No posts ranked'
        ELSE 'Ranked as ' || r.ViewRank::TEXT || ' by views'
    END AS ViewRankComment,
    CASE 
        WHEN r.RecentRank < 10 THEN 'Recent high activity'
        ELSE 'Less recent activity'
    END AS RecentActivityComment,
    CASE 
        WHEN r.ScoreRank = 1 THEN 'Top scorer!'
        ELSE 'Score below top rank'
    END AS ScoreComment
FROM 
    AggregatedData a
LEFT JOIN 
    RankedPosts r ON a.UserId = r.PostId
WHERE 
    a.TotalViews > 500
ORDER BY 
    a.BadgeCount DESC, a.TotalViews DESC, r.ViewCount DESC NULLS LAST
OFFSET 5 ROWS
FETCH NEXT 10 ROWS ONLY;
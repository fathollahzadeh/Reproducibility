
WITH PostEngagement AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.AnswerCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS EngagementScore, 
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 YEAR'
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.AnswerCount
),
PostHistoryCounts AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS RevisionCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseReopenCount
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 YEAR'
    GROUP BY 
        ph.PostId
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    WHERE 
        b.Class = 1 
    GROUP BY 
        b.UserId
)
SELECT 
    pe.PostId,
    pe.Title,
    pe.ViewCount,
    pe.AnswerCount,
    pe.EngagementScore,
    ph.RevisionCount,
    ph.CloseReopenCount,
    ub.BadgeCount,
    CASE 
        WHEN ub.BadgeCount IS NULL THEN 'No Gold Badges'
        ELSE 'Has Gold Badges'
    END AS BadgeStatus
FROM 
    PostEngagement pe
LEFT JOIN 
    PostHistoryCounts ph ON pe.PostId = ph.PostId
LEFT JOIN 
    UserBadges ub ON pe.PostId = ub.UserId
WHERE 
    NOT EXISTS (SELECT 1 FROM Comments c WHERE c.PostId = pe.PostId AND c.UserId IS NULL) 
ORDER BY 
    pe.EngagementScore DESC
LIMIT 50;

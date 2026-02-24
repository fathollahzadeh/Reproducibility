
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) as PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveQuestions
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 100 
    GROUP BY 
        u.Id, u.Reputation
),
PostHistories AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserId,
        COUNT(*) AS HistoryCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12) 
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId, ph.CreationDate, ph.UserId
),
UserBadgeCounts AS (
    SELECT
        ub.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users ub
    LEFT JOIN 
        Badges b ON ub.Id = b.UserId
    GROUP BY 
        ub.Id
)
SELECT 
    u.DisplayName AS UserDisplayName,
    us.Reputation,
    us.QuestionCount,
    us.TotalViews,
    RPP.Id AS PostId,
    RPP.Title,
    RPP.CreationDate,
    RPP.Score,
    PH.HistoryCount,
    UBC.BadgeCount,
    CASE 
        WHEN PH.PostHistoryTypeId IS NOT NULL THEN 
            CASE 
                WHEN PH.PostHistoryTypeId = 10 THEN 'Closed'
                WHEN PH.PostHistoryTypeId = 11 THEN 'Reopened'
                WHEN PH.PostHistoryTypeId = 12 THEN 'Deleted'
            END
        ELSE 'No Action'
    END AS LastAction
FROM 
    UserStats us
JOIN 
    Users u ON us.UserId = u.Id
LEFT JOIN 
    RankedPosts RPP ON u.Id = RPP.OwnerUserId AND RPP.PostRank = 1 
LEFT JOIN 
    PostHistories PH ON RPP.Id = PH.PostId
LEFT JOIN 
    UserBadgeCounts UBC ON u.Id = UBC.UserId
WHERE 
    us.QuestionCount > 0
ORDER BY 
    us.Reputation DESC,
    us.TotalViews DESC;

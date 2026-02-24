WITH RecursivePostRank AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.AnswerCount,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
UserReputationHistory AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.CreationDate,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
),
CloseReasons AS (
    SELECT 
        ph.PostId,
        ph.Comment,
        MAX(ph.CreationDate) AS LastCloseDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        ph.PostId, ph.Comment
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    p.Title AS QuestionTitle,
    p.Score AS QuestionScore,
    p.ViewCount AS ViewCount,
    up.DisplayName AS QuestionOwner,
    up.Reputation,
    up.CreationDate AS UserCreationDate,
    COALESCE(b.BadgeCount, 0) AS UserBadgeCount,
    cr.LastCloseDate,
    cr.Comment AS CloseReason,
    rpr.Rank AS UserPostRank
FROM 
    Posts p
JOIN 
    Users up ON p.OwnerUserId = up.Id
LEFT JOIN 
    UserBadges b ON up.Id = b.UserId
LEFT JOIN 
    UserReputationHistory ur ON up.Id = ur.UserId
LEFT JOIN 
    RecursivePostRank rpr ON p.Id = rpr.Id
LEFT JOIN 
    CloseReasons cr ON p.Id = cr.PostId
WHERE 
    p.LastActivityDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 YEAR'
    AND (p.ViewCount > 100 OR p.Score > 0)
ORDER BY 
    p.Score DESC,
    p.ViewCount DESC;
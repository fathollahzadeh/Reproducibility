WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.OwnerUserId,
        p.CreationDate,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore,
        COUNT(*) OVER (PARTITION BY p.OwnerUserId) AS TotalPosts
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        DENSE_RANK() OVER (ORDER BY SUM(p.Score) DESC) AS ReputationRank,
        AVG(p.ViewCount) AS AvgViewCount
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
    HAVING 
        COUNT(p.Id) > 5
),
ClosureReasons AS (
    SELECT 
        ph.PostId,
        STRING_AGG(cr.Name, ', ') AS CloseReasons,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
),
UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames,
        COUNT(*) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)

SELECT 
    pu.DisplayName,
    pu.Reputation,
    pu.ReputationRank,
    pu.AvgViewCount,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    cb.CloseReasons,
    ub.BadgeNames,
    GREATEST(rp.ViewCount, COALESCE(cb.CloseCount, 0)) AS MaxImportantMetric,
    CASE 
        WHEN cb.CloseCount IS NULL THEN 'No Closures'
        WHEN cb.CloseCount > 5 THEN 'Frequent Closures'
        ELSE 'Moderate Closures'
    END AS ClosureFrequency
FROM 
    TopUsers pu
JOIN 
    RankedPosts rp ON pu.UserId = rp.OwnerUserId AND rp.RankByScore = 1
LEFT JOIN 
    ClosureReasons cb ON rp.Id = cb.PostId
LEFT JOIN 
    UserBadges ub ON pu.UserId = ub.UserId
WHERE 
    pu.ReputationRank <= 10
ORDER BY 
    pu.Reputation DESC,
    rp.Score DESC;
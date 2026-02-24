
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
        AND p.Score IS NOT NULL
),
TopUsers AS (
    SELECT 
        u.Id AS UserID,
        u.DisplayName,
        SUM(CASE WHEN p.Score IS NOT NULL THEN p.Score ELSE 0 END) AS TotalScore,
        COUNT(DISTINCT p.Id) AS TotalPosts
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),
UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    WHERE 
        b.Class = 1 
    GROUP BY 
        b.UserId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        ph.PostId
)
SELECT 
    u.DisplayName,
    u.TotalScore,
    u.TotalPosts,
    COALESCE(ub.BadgeNames, 'No Gold Badges') AS GoldBadges,
    COALESCE(cp.CloseCount, 0) AS ClosedPostsCount,
    rp.Title AS TopPostTitle,
    rp.Score AS TopPostScore
FROM 
    TopUsers u
LEFT JOIN 
    UserBadges ub ON u.UserID = ub.UserId
LEFT JOIN 
    ClosedPosts cp ON u.UserID = cp.PostId
LEFT JOIN 
    RankedPosts rp ON u.UserID = rp.OwnerUserId AND rp.ScoreRank = 1
WHERE 
    u.TotalPosts > 5
ORDER BY 
    u.TotalScore DESC, 
    u.TotalPosts DESC;

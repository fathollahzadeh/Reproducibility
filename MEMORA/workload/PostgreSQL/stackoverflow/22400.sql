
WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        ph.UserId AS CloserId,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        p.Id, p.Title, ph.UserId
),
PostScores AS (
    SELECT 
        p.Id AS PostId,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Score,
        ROW_NUMBER() OVER (ORDER BY COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
TopUsers AS (
    SELECT 
        ub.UserId,
        ub.DisplayName,
        ub.BadgeCount,
        cp.PostId,
        ps.Score
    FROM 
        UserBadges ub
    INNER JOIN 
        ClosedPosts cp ON cp.CloserId = ub.UserId
    LEFT JOIN 
        PostScores ps ON ps.PostId = cp.PostId
    WHERE 
        ub.BadgeCount > 0 AND ps.Score IS NOT NULL
)
SELECT 
    tu.DisplayName,
    tu.BadgeCount,
    COALESCE(SUM(ps.Score), 0) AS TotalScore,
    (SELECT COUNT(*) FROM Posts p WHERE p.OwnerUserId = tu.UserId AND p.CreationDate < (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '6 months')) AS OldPostCount,
    CASE 
        WHEN SUM(ps.Score) IS NULL THEN 'No Score Yet'
        WHEN SUM(ps.Score) > 100 THEN 'Highly Rated'
        ELSE 'Emerging Contributor'
    END AS ContributionLevel
FROM 
    TopUsers tu
LEFT JOIN 
    PostScores ps ON ps.PostId = tu.PostId
GROUP BY 
    tu.UserId, tu.DisplayName, tu.BadgeCount
HAVING 
    COUNT(DISTINCT tu.PostId) > 1
ORDER BY 
    TotalScore DESC, tu.BadgeCount DESC, tu.DisplayName
LIMIT 10;

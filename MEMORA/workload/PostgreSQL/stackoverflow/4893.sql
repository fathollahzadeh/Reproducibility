
WITH TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),
PostStatistics AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        (p.ViewCount - COALESCE((SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id), 0)) AS ViewCountAdjusted,
        PERCENT_RANK() OVER (ORDER BY p.Score DESC) AS ScoreRank,
        DENSE_RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '1 year'
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS CloseDate,
        ctr.Name AS CloseReason
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes ctr ON (ph.Comment::json->>'CloseReasonId')::int = ctr.Id
    WHERE 
        ph.PostHistoryTypeId = 10
)
SELECT 
    tu.DisplayName,
    tu.PostCount,
    tu.TotalUpVotes,
    tu.TotalDownVotes,
    tu.GoldBadges,
    tu.SilverBadges,
    tu.BronzeBadges,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCountAdjusted,
    cp.CloseDate,
    cp.CloseReason
FROM 
    TopUsers tu
JOIN 
    PostStatistics ps ON ps.Id IN (SELECT AcceptedAnswerId FROM Posts WHERE OwnerUserId = tu.UserId)
LEFT JOIN 
    ClosedPosts cp ON cp.PostId = ps.Id
ORDER BY 
    tu.TotalUpVotes DESC, ps.ScoreRank ASC
LIMIT 50;

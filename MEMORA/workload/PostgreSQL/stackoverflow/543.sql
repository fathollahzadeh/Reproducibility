
WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) FILTER (WHERE b.Class = 1) AS GoldBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 2) AS SilverBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 3) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostScores AS (
    SELECT 
        p.Id AS PostId,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS NetScore,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) AS UniqueVoters
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3)  
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY p.Id
),
RankedPosts AS (
    SELECT 
        ps.PostId,
        ps.NetScore,
        ps.CommentCount,
        ROW_NUMBER() OVER (ORDER BY ps.NetScore DESC, ps.CommentCount DESC) AS Rank
    FROM PostScores ps
),
TopUsers AS (
    SELECT 
        ub.UserId,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges,
        ROW_NUMBER() OVER (ORDER BY (ub.GoldBadges + ub.SilverBadges * 0.5 + ub.BronzeBadges * 0.25) DESC) AS UserRank
    FROM UserBadges ub
)
SELECT 
    pu.UserId,
    pu.UserRank,
    rp.PostId,
    rp.NetScore,
    rp.CommentCount
FROM TopUsers pu
JOIN RankedPosts rp ON pu.UserRank <= 10  
WHERE rp.NetScore > 0  
ORDER BY pu.UserRank, rp.NetScore DESC
LIMIT 5;

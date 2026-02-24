
WITH UserVotes AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS Downvotes,
        SUM(CASE WHEN v.VoteTypeId IN (2, 3) THEN (CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE -1 END) ELSE 0 END) AS VoteBalance,
        ROW_NUMBER() OVER (PARTITION BY u.Reputation ORDER BY COUNT(v.VoteTypeId) DESC) AS VoteRank
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    WHERE u.Reputation IS NOT NULL 
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentsCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        COUNT(DISTINCT b.Id) AS TotalBadges
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Badges b ON p.OwnerUserId = b.UserId
    WHERE p.CreationDate > (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
    GROUP BY p.Id, p.Title, p.CreationDate
),
RankedPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.CommentsCount,
        ps.GoldBadges,
        ps.SilverBadges,
        ps.BronzeBadges,
        ps.TotalBadges,
        DENSE_RANK() OVER (ORDER BY ps.CommentsCount DESC, ps.TotalBadges DESC) AS PostRank
    FROM PostStats ps
)
SELECT 
    uv.DisplayName,
    rp.Title,
    rp.CommentsCount,
    rp.GoldBadges,
    rp.SilverBadges,
    rp.BronzeBadges,
    uv.VoteBalance,
    CASE 
        WHEN rp.PostRank <= 10 THEN 'Top Posts'
        ELSE 'Other Posts'
    END AS PostCategory
FROM RankedPosts rp
JOIN UserVotes uv ON uv.UserId = (SELECT DISTINCT OwnerUserId FROM Posts WHERE Id = rp.PostId)
WHERE uv.VoteBalance > 0
    AND rp.CommentsCount < (SELECT AVG(CommentsCount) FROM PostStats)
    AND rp.GoldBadges IS NOT NULL
ORDER BY uv.VoteBalance DESC, rp.CommentsCount ASC
LIMIT 20;

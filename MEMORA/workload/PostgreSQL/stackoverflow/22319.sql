
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY p.Id, p.Title, p.CreationDate, p.ViewCount, p.OwnerUserId
),
PostSummary AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        CASE 
            WHEN rp.UpVotes - rp.DownVotes > 0 THEN 'Positive'
            WHEN rp.UpVotes - rp.DownVotes < 0 THEN 'Negative'
            ELSE 'Neutral'
        END AS Sentiment,
        CASE 
            WHEN rp.Rank = 1 THEN 'Most Recent Post'
            ELSE 'Older Post'
        END AS PostRecency
    FROM RankedPosts rp
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges,
        COUNT(DISTINCT ps.PostId) AS PostsCount,
        COUNT(DISTINCT ps.PostId) FILTER (WHERE ps.Sentiment = 'Positive') AS PositivePosts,
        COUNT(DISTINCT ps.PostId) FILTER (WHERE ps.Sentiment = 'Negative') AS NegativePosts
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN PostSummary ps ON u.Id = (SELECT OwnerUserId FROM Posts WHERE Id = ps.PostId)
    GROUP BY u.Id, u.DisplayName, u.Reputation
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges,
    us.PostsCount,
    us.PositivePosts,
    us.NegativePosts,
    CASE 
        WHEN us.Reputation > 1000 THEN 'Expert'
        WHEN us.Reputation BETWEEN 500 AND 1000 THEN 'Intermediate'
        ELSE 'Novice'
    END AS UserLevel,
    ARRAY_AGG(CONCAT_WS(' - ', ps.Title, ps.Sentiment)) AS PostSummaries
FROM UserStats us
LEFT JOIN PostSummary ps ON us.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = ps.PostId)
GROUP BY us.UserId, us.DisplayName, us.Reputation, us.GoldBadges, us.SilverBadges, us.BronzeBadges, us.PostsCount, us.PositivePosts, us.NegativePosts
ORDER BY us.Reputation DESC;

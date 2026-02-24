
WITH RankedPosts AS (
    SELECT p.Id AS PostId,
           p.Title,
           p.OwnerUserId,
           p.CreationDate,
           p.Score,
           p.ViewCount,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
           COALESCE(v.UpVotes, 0) AS UpVotes,
           COALESCE(v.DownVotes, 0) AS DownVotes,
           U.Reputation,
           U.DisplayName AS OwnerDisplayName,
           U.Views AS OwnerViews
    FROM Posts p
    LEFT JOIN Users U ON p.OwnerUserId = U.Id
    LEFT JOIN (
        SELECT PostId,
               SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
               SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM Votes
        GROUP BY PostId
    ) v ON p.Id = v.PostId
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),

PopularPosts AS (
    SELECT PostId, Title, OwnerUserId, Score, UpVotes, DownVotes, Rank
    FROM RankedPosts
    WHERE Rank <= 5
),

PostStatistics AS (
    SELECT pp.PostId,
           pp.Title,
           pp.OwnerUserId,
           pp.Score,
           pp.UpVotes,
           pp.DownVotes,
           (pp.UpVotes * 1.0 / NULLIF((pp.UpVotes + pp.DownVotes), 0)) AS UpvoteRatio,
           COUNT(DISTINCT c.Id) AS CommentCount,
           COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
           COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
           COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
    FROM PopularPosts pp
    LEFT JOIN Comments c ON pp.PostId = c.PostId
    LEFT JOIN Badges b ON pp.OwnerUserId = b.UserId
    GROUP BY pp.PostId, pp.Title, pp.OwnerUserId, pp.Score, pp.UpVotes, pp.DownVotes
)

SELECT ps.PostId,
       ps.Title,
       ps.OwnerUserId,
       u.DisplayName,
       ps.Score,
       ps.UpVotes,
       ps.DownVotes,
       ps.UpvoteRatio,
       ps.CommentCount,
       ps.GoldBadges,
       ps.SilverBadges,
       ps.BronzeBadges
FROM PostStatistics ps
INNER JOIN Users u ON ps.OwnerUserId = u.Id
WHERE ps.CommentCount > 2
   OR ps.UpvoteRatio IS NULL
   OR u.Reputation > (SELECT AVG(Reputation) FROM Users WHERE Reputation IS NOT NULL)  
ORDER BY ps.Score DESC, u.Reputation DESC;

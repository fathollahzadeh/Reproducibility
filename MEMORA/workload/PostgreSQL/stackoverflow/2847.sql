
WITH UserReputation AS (
    SELECT u.Id AS UserId, u.DisplayName, u.Reputation,
           COUNT(b.Id) AS BadgeCount,
           SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
           SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
           SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT UserId, DisplayName, Reputation,
           RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM UserReputation
),
PostDetails AS (
    SELECT p.Id AS PostId, p.Title, p.Body, 
           p.CreationDate, p.OwnerUserId, 
           STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
           COUNT(DISTINCT c.Id) AS CommentCount,
           COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
           COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes,
           COALESCE(MAX(ph.CreationDate), p.CreationDate) AS LastEditDate
    FROM Posts p
    LEFT JOIN Tags t ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (4, 5)
    WHERE p.CreationDate > (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
    GROUP BY p.Id, p.Title, p.Body, p.CreationDate, p.OwnerUserId
)
SELECT u.UserId, u.DisplayName, p.Title, 
       p.Tags, p.CommentCount, p.UpVotes,
       p.DownVotes, p.LastEditDate
FROM TopUsers u
JOIN PostDetails p ON u.UserId = p.OwnerUserId
WHERE u.ReputationRank <= 10
ORDER BY u.Reputation DESC, p.UpVotes DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;

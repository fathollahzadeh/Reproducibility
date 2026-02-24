
WITH UserReputation AS (
    SELECT Id, Reputation, CreationDate, DisplayName, LastAccessDate 
    FROM Users 
    WHERE Reputation > 1000
), 
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        MAX(ph.CreationDate) AS LastEdited
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE p.PostTypeId = 1 
    GROUP BY p.Id, p.Title, p.Score, p.ViewCount
), 
BadgeSummary AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS TotalBadges,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Badges b
    GROUP BY b.UserId
)
SELECT 
    ur.DisplayName,
    ur.Reputation,
    ps.Title,
    ps.Score,
    ps.ViewCount,
    ps.CommentCount,
    ps.VoteCount,
    ps.UpVotes,
    ps.DownVotes,
    bs.TotalBadges,
    bs.GoldBadges,
    bs.SilverBadges,
    bs.BronzeBadges,
    ps.LastEdited
FROM UserReputation ur
JOIN Posts p ON ur.Id = p.OwnerUserId
JOIN PostStatistics ps ON p.Id = ps.PostId
LEFT JOIN BadgeSummary bs ON ur.Id = bs.UserId
WHERE ur.CreationDate < TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
ORDER BY ur.Reputation DESC, ps.ViewCount DESC
LIMIT 50;


WITH RankedUsers AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation, 
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM Users u
),
ActivePosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.OwnerUserId, 
        COUNT(c.Id) AS CommentCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate > DATE '2024-10-01' - INTERVAL '1 year' AND p.Score > 10
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
),
BadgeCounts AS (
    SELECT 
        b.UserId, 
        COUNT(b.Id) AS BadgeCount
    FROM Badges b
    GROUP BY b.UserId
),
PostVoteSummary AS (
    SELECT 
        p.Id AS PostId, 
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id
)
SELECT 
    ru.DisplayName,
    ru.Reputation,
    ru.ReputationRank,
    ap.Title,
    ap.CreationDate,
    ap.CommentCount,
    COALESCE(bc.BadgeCount, 0) AS BadgeCount,
    COALESCE(pvs.UpVotes, 0) AS UpVotes,
    COALESCE(pvs.DownVotes, 0) AS DownVotes
FROM RankedUsers ru
JOIN ActivePosts ap ON ru.UserId = ap.OwnerUserId
LEFT JOIN BadgeCounts bc ON ru.UserId = bc.UserId
LEFT JOIN PostVoteSummary pvs ON ap.PostId = pvs.PostId
ORDER BY ru.Reputation DESC, ap.Score DESC
LIMIT 50;

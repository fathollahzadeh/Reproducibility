
WITH UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation,
        CreationDate,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
),
RecentPostStats AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVoteCount, 
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVoteCount 
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days' 
    GROUP BY p.Id, p.OwnerUserId
),
PostHistoryAggregate AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes,
        MAX(ph.CreationDate) AS LastEditedDate,
        COUNT(*) FILTER (WHERE ph.PostHistoryTypeId IN (10, 11, 12, 13, 14, 15)) AS ClosureCount 
    FROM PostHistory ph
    JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY ph.PostId
)
SELECT 
    up.UserId,
    up.Reputation,
    rps.PostId,
    rps.CommentCount,
    rps.UpVoteCount,
    rps.DownVoteCount,
    COALESCE(pha.HistoryTypes, 'None') AS PostHistory,
    pha.LastEditedDate,
    pha.ClosureCount,
    CASE 
        WHEN rps.UpVoteCount > rps.DownVoteCount THEN 'Positive Engagement'
        WHEN rps.UpVoteCount < rps.DownVoteCount THEN 'Negative Engagement'
        ELSE 'Neutral Engagement'
    END AS EngagementStatus,
    CASE 
        WHEN up.ReputationRank IS NULL THEN 'No Reputation Rank'
        ELSE CAST(up.ReputationRank AS VARCHAR) || ' - ' || CAST(up.Reputation AS VARCHAR) 
    END AS UserReputationRank
FROM UserReputation up
LEFT JOIN RecentPostStats rps ON up.UserId = rps.OwnerUserId
LEFT JOIN PostHistoryAggregate pha ON rps.PostId = pha.PostId
WHERE up.CreationDate < TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
ORDER BY rps.UpVoteCount DESC, rps.DownVoteCount ASC
LIMIT 100;

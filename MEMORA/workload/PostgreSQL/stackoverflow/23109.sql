
WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        CASE 
            WHEN u.Reputation >= 1000 THEN 'High Reputation'
            WHEN u.Reputation >= 500 THEN 'Medium Reputation'
            ELSE 'Low Reputation'
        END AS ReputationLevel
    FROM Users u
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        PERCENT_RANK() OVER (ORDER BY COUNT(c.Id) DESC) AS CommentRank
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id, p.Title
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN pht.Name = 'Post Closed' THEN ph.CreationDate END) AS LastClosedDate,
        MAX(CASE WHEN pht.Name = 'Post Reopened' THEN ph.CreationDate END) AS LastReopenedDate,
        COUNT(CASE WHEN pht.Name IN ('Edit Body', 'Edit Title') THEN 1 END) AS EditCount
    FROM PostHistory ph
    JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY ph.PostId
)
SELECT 
    p.Title,
    ps.CommentCount,
    ps.UpVotes,
    ps.DownVotes,
    CASE 
        WHEN (ps.UpVotes - ps.DownVotes) > 0 THEN 'Positive'
        WHEN (ps.UpVotes - ps.DownVotes) < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment,
    ur.ReputationLevel,
    COALESCE(PHD.LastClosedDate, PHD.LastReopenedDate) AS LastStatusChange,
    PHD.EditCount
FROM PostStatistics ps
JOIN Posts p ON ps.PostId = p.Id
JOIN UserReputation ur ON p.OwnerUserId = ur.UserId
LEFT JOIN PostHistoryDetails PHD ON p.Id = PHD.PostId
WHERE 
    ur.ReputationLevel <> 'Low Reputation' 
    AND ps.CommentRank < 0.25
    AND (COALESCE(PHD.LastClosedDate, PHD.LastReopenedDate) IS NOT NULL OR ps.CommentCount > 5)
ORDER BY 
    ps.CommentCount DESC,
    ps.UpVotes DESC;

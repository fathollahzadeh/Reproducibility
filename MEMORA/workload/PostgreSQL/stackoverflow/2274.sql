
WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM Users u
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        COALESCE(NULLIF(p.AcceptedAnswerId, -1), 0) AS HasAcceptedAnswer,
        EXTRACT(YEAR FROM p.CreationDate) AS PostYear,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id, p.Title, p.Score, p.ViewCount, p.AcceptedAnswerId, p.CreationDate
),
PostHistoryAggregated AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS HistoryCount,
        MAX(ph.CreationDate) AS LastRevisionDate
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (10, 11, 19)
    GROUP BY ph.PostId, ph.PostHistoryTypeId
),
TopPosts AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.Score,
        pd.ViewCount,
        pd.HasAcceptedAnswer,
        pd.UpVotes,
        pd.DownVotes,
        ph.LastRevisionDate,
        ur.Reputation,
        ur.ReputationRank
    FROM PostDetails pd
    LEFT JOIN PostHistoryAggregated ph ON pd.PostId = ph.PostId
    JOIN UserReputation ur ON pd.HasAcceptedAnswer = ur.UserId
    WHERE pd.HasAcceptedAnswer > 0
    ORDER BY pd.Score DESC, pd.ViewCount DESC
    LIMIT 10
)

SELECT 
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tp.UpVotes,
    tp.DownVotes,
    tp.LastRevisionDate,
    tp.Reputation,
    tp.ReputationRank,
    CASE 
        WHEN tp.Reputation > 1000 THEN 'Expert'
        WHEN tp.Reputation BETWEEN 500 AND 1000 THEN 'Intermediate'
        ELSE 'Novice' 
    END AS UserLevel
FROM TopPosts tp
WHERE tp.LastRevisionDate IS NOT NULL
UNION ALL
SELECT 
    'No Accepted Answers' AS Title,
    0 AS Score,
    0 AS ViewCount,
    0 AS UpVotes,
    0 AS DownVotes,
    CAST('2024-10-01 12:34:56' AS TIMESTAMP) AS LastRevisionDate,
    AVG(ur.Reputation) AS AvgReputation,
    NULL AS ReputationRank,
    'N/A' AS UserLevel
FROM UserReputation ur
WHERE ur.UserId NOT IN (SELECT DISTINCT pd.HasAcceptedAnswer FROM PostDetails pd)
GROUP BY ur.UserId;

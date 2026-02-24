WITH UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM Users u
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        COUNT(c.Id) AS TotalComments,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        MAX(COALESCE(p.LastActivityDate, p.CreationDate)) AS MostRecentActivity
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY p.Id, p.OwnerUserId
),
PostDetails AS (
    SELECT 
        ps.PostId,
        ur.DisplayName AS OwnerDisplayName,
        ps.TotalComments,
        ps.UpVotes,
        ps.DownVotes,
        CASE 
            WHEN ps.UpVotes - ps.DownVotes > 0 
            THEN 'Positive' 
            WHEN ps.UpVotes - ps.DownVotes < 0 
            THEN 'Negative' 
            ELSE 'Neutral' 
        END AS VoteSentiment,
        COUNT(ph.Id) FILTER (WHERE ph.PostHistoryTypeId = 10) AS CloseCount,
        COUNT(ph.Id) FILTER (WHERE ph.PostHistoryTypeId = 11) AS ReopenCount
    FROM PostStats ps
    LEFT JOIN UserReputation ur ON ps.OwnerUserId = ur.UserId
    LEFT JOIN PostHistory ph ON ps.PostId = ph.PostId
    WHERE ur.ReputationRank <= 10
    GROUP BY ps.PostId, ur.DisplayName, ps.TotalComments, ps.UpVotes, ps.DownVotes
)
SELECT 
    pd.OwnerDisplayName,
    pd.TotalComments,
    pd.UpVotes,
    pd.DownVotes,
    pd.VoteSentiment,
    pd.CloseCount,
    pd.ReopenCount,
    (pd.UpVotes + pd.ReopenCount - pd.CloseCount - pd.DownVotes) AS EngagementScore
FROM PostDetails pd
WHERE pd.CloseCount > pd.ReopenCount
ORDER BY EngagementScore DESC
LIMIT 10;
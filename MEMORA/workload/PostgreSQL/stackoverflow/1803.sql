
WITH UserReputation AS (
    SELECT Id, Reputation, 
           RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
), 
PostDetails AS (
    SELECT p.Id AS PostId, 
           p.Title, 
           p.ViewCount, 
           u.DisplayName AS OwnerDisplayName, 
           COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - 
                     SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS NetScore
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.PostTypeId = 1 
    GROUP BY p.Id, p.Title, p.ViewCount, u.DisplayName
), 
ClosedPosts AS (
    SELECT ph.PostId, 
           COUNT(ph.Id) AS CloseCount, 
           STRING_AGG(COALESCE(ct.Name, 'Unknown'), ', ') AS CloseReasons
    FROM PostHistory ph
    LEFT JOIN CloseReasonTypes ct ON CAST(ph.Comment AS INT) = ct.Id
    WHERE ph.PostHistoryTypeId = 10 
    GROUP BY ph.PostId
), 
PopularPosts AS (
    SELECT pd.PostId, 
           pd.Title, 
           pd.OwnerDisplayName, 
           pd.ViewCount, 
           pd.NetScore, 
           cp.CloseCount, 
           cp.CloseReasons,
           ROW_NUMBER() OVER (ORDER BY pd.NetScore DESC, pd.ViewCount DESC) AS PopularityRank
    FROM PostDetails pd
    LEFT JOIN ClosedPosts cp ON pd.PostId = cp.PostId
    WHERE pd.NetScore > 0 
)

SELECT up.Reputation, 
       up.ReputationRank, 
       pp.Title, 
       pp.OwnerDisplayName, 
       pp.ViewCount, 
       pp.NetScore, 
       pp.CloseCount,
       pp.CloseReasons
FROM UserReputation up
JOIN PopularPosts pp ON up.Id = (SELECT OwnerUserId FROM Posts WHERE Id = pp.PostId)
WHERE up.ReputationRank <= 10 
ORDER BY up.ReputationRank, pp.NetScore DESC;

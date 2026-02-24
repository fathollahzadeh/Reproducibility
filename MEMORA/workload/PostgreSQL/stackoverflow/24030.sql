WITH UserReputation AS (
    SELECT 
        Id,
        DisplayName,
        Reputation,
        CASE 
            WHEN Reputation >= 1000 THEN 'High Reputation'
            WHEN Reputation BETWEEN 500 AND 999 THEN 'Medium Reputation'
            ELSE 'Low Reputation'
        END AS ReputationLevel
    FROM Users
),
NestedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        p.Body,
        p.Score,
        COALESCE(c.CreationDate, p.CreationDate) AS FirstActivityDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate) AS PostOrder,
        COUNT(*) OVER (PARTITION BY p.OwnerUserId) AS TotalPosts
    FROM Posts p
    LEFT JOIN Comments c ON c.PostId = p.Id
    WHERE p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
),
PostVoteCounts AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Votes
    GROUP BY PostId
),
PostDetails AS (
    SELECT 
        np.PostId,
        np.Title,
        np.CreationDate,
        np.Body,
        np.Score,
        np.FirstActivityDate,
        ur.DisplayName AS Author,
        ur.ReputationLevel,
        pvc.UpVotes,
        pvc.DownVotes,
        (np.Score + COALESCE(pvc.UpVotes, 0) - COALESCE(pvc.DownVotes, 0)) AS NetScore
    FROM NestedPosts np
    JOIN UserReputation ur ON np.OwnerUserId = ur.Id
    LEFT JOIN PostVoteCounts pvc ON np.PostId = pvc.PostId
)
SELECT 
    pd.Title,
    pd.Author,
    pd.ReputationLevel,
    pd.NetScore,
    pd.CreationDate,
    pd.Body,
    pd.FirstActivityDate,
    CASE 
        WHEN pd.NetScore > 10 THEN 'Highly Engaging'
        WHEN pd.NetScore BETWEEN -10 AND 10 THEN 'Moderately Engaging'
        ELSE 'Low Engagement'
    END AS EngagementLevel,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = pd.PostId) AS CommentCount
FROM PostDetails pd
WHERE pd.ReputationLevel = 'High Reputation'
  AND pd.CreationDate BETWEEN cast('2024-10-01' as date) - INTERVAL '6 MONTH' AND cast('2024-10-01' as date)
  AND pd.PostId NOT IN (SELECT RelatedPostId FROM PostLinks)
ORDER BY pd.NetScore DESC, pd.CreationDate ASC
LIMIT 100;
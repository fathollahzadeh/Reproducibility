WITH RecentPosts AS (
    SELECT Id, Title, OwnerUserId, CreationDate, ViewCount, Score,
           ROW_NUMBER() OVER (PARTITION BY OwnerUserId ORDER BY CreationDate DESC) AS rn
    FROM Posts
    WHERE CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
),
UserReputation AS (
    SELECT Id, Reputation, DisplayName, 
           CASE 
               WHEN Reputation >= 1000 THEN 'High' 
               WHEN Reputation >= 100 THEN 'Medium' 
               ELSE 'Low' 
           END AS ReputationLevel
    FROM Users
),
PostVoteCounts AS (
    SELECT PostId, 
           COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS Upvotes,
           COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS Downvotes
    FROM Votes
    GROUP BY PostId
),
ClosedPosts AS (
    SELECT Ph.PostId, COUNT(*) AS CloseCount
    FROM PostHistory Ph
    WHERE Ph.PostHistoryTypeId = 10
    GROUP BY Ph.PostId
)

SELECT 
    p.Id AS PostId,
    p.Title,
    u.DisplayName AS Author,
    p.CreationDate,
    COALESCE(v.Upvotes, 0) AS Upvotes,
    COALESCE(v.Downvotes, 0) AS Downvotes,
    CASE 
        WHEN c.CloseCount IS NOT NULL THEN 'Closed' 
        ELSE 'Open' 
    END AS PostStatus,
    rp.rn AS RecentPostRank,
    ur.ReputationLevel
FROM 
    RecentPosts rp
JOIN 
    Posts p ON p.Id = rp.Id
JOIN 
    Users u ON u.Id = p.OwnerUserId
LEFT JOIN 
    PostVoteCounts v ON v.PostId = p.Id
LEFT JOIN 
    ClosedPosts c ON c.PostId = p.Id
JOIN 
    UserReputation ur ON ur.Id = p.OwnerUserId
WHERE 
    ur.ReputationLevel = 'High' 
    OR (ur.ReputationLevel = 'Medium' AND p.ViewCount > 100)
ORDER BY 
    p.Score DESC, p.CreationDate DESC;
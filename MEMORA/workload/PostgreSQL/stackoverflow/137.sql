WITH UserReputation AS (
    SELECT Id, Reputation, 
           ROW_NUMBER() OVER (PARTITION BY CASE WHEN Reputation < 1000 THEN 'Low' 
                                                 WHEN Reputation BETWEEN 1000 AND 5000 THEN 'Medium' 
                                                 ELSE 'High' END 
                              ORDER BY Reputation DESC) AS Rank
    FROM Users
),
RecentPosts AS (
    SELECT P.Id AS PostId, P.OwnerUserId, P.PostTypeId, P.CreationDate,
           COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
           COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
           COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN Comments C ON P.Id = C.PostId
    WHERE P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY P.Id, P.OwnerUserId, P.PostTypeId, P.CreationDate
),
PostStats AS (
    SELECT R.OwnerUserId, R.PostId, R.Upvotes, R.Downvotes, R.CommentCount,
           U.Rank AS ReputationRank
    FROM RecentPosts R
    JOIN UserReputation U ON R.OwnerUserId = U.Id
)
SELECT U.DisplayName,
       COUNT(DISTINCT P.PostId) AS TotalPosts,
       SUM(P.Upvotes) AS TotalUpvotes,
       SUM(P.Downvotes) AS TotalDownvotes,
       AVG(P.CommentCount) AS AvgComments,
       CASE WHEN AVG(P.CommentCount) IS NULL THEN 'No Comments' 
            ELSE CASE WHEN AVG(P.CommentCount) = 0 THEN 'No Interaction' 
                      ELSE 'Engaged' END END AS EngagementStatus
FROM PostStats P
JOIN Users U ON P.OwnerUserId = U.Id
GROUP BY U.DisplayName, P.ReputationRank
HAVING COUNT(DISTINCT P.PostId) > 5
ORDER BY TotalUpvotes DESC NULLS LAST;
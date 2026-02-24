
WITH 
  UserReputation AS (
    SELECT 
      Id, 
      DisplayName, 
      Reputation, 
      LastAccessDate, 
      CASE 
        WHEN Reputation IS NULL THEN 'Unknown Reputation'
        WHEN Reputation < 100 THEN 'Low Reputation'
        WHEN Reputation BETWEEN 100 AND 1000 THEN 'Medium Reputation'
        ELSE 'High Reputation' 
      END AS ReputationCategory
    FROM Users
  ),
  
  PostStats AS (
    SELECT 
      P.Id AS PostId,
      P.Title,
      P.CreationDate,
      P.PostTypeId,
      COALESCE(P.AcceptedAnswerId, 0) AS AcceptedAnswerId,
      COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS TotalComments,
      COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
      COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
      P.OwnerUserId,
      RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY COUNT(V.Id) DESC) AS UserPostRank
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY P.Id, P.Title, P.CreationDate, P.PostTypeId, P.AcceptedAnswerId, P.OwnerUserId
  ),

  PopularPosts AS (
    SELECT 
      PS.PostId,
      PS.Title,
      PS.UpVotes,
      PS.DownVotes,
      PS.TotalComments,
      PS.CreationDate,
      U.DisplayName AS OwnerDisplayName,
      U.Reputation,
      PS.UserPostRank
    FROM PostStats PS
    JOIN UserReputation U ON PS.OwnerUserId = U.Id
    WHERE U.Reputation IS NOT NULL
  )

SELECT 
  PP.PostId,
  PP.Title,
  PP.OwnerDisplayName,
  PP.UpVotes,
  PP.DownVotes,
  PP.TotalComments,
  CASE 
    WHEN PP.UserPostRank = 1 THEN 'Top Contributor'
    WHEN PP.UserPostRank BETWEEN 2 AND 5 THEN 'Notable Contributor'
    ELSE 'Regular Contributor' 
  END AS ContributorStatus,
  DATE_PART('day', TIMESTAMP '2024-10-01 12:34:56' - PP.CreationDate) AS DaysSincePosted,
  CASE 
    WHEN PP.UpVotes - PP.DownVotes > 50 THEN 'Highly Upvoted'
    WHEN PP.UpVotes < PP.DownVotes THEN 'More Downvotes Than Upvotes'
    ELSE 'Moderate Engagement' 
  END AS EngagementStatus
FROM PopularPosts PP
WHERE PP.UpVotes > 10 OR 
      (PP.TotalComments > 5 AND PP.UserPostRank < 4)
ORDER BY PP.UpVotes DESC, DaysSincePosted ASC
LIMIT 100;

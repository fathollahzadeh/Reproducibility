
WITH UserRankings AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
), HighReputationUsers AS (
    SELECT 
        UserId,
        DisplayName,
        ReputationRank
    FROM UserRankings
    WHERE ReputationRank <= 10
), RecentPostCounts AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS RecentPostsCount
    FROM Posts P
    WHERE P.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY P.OwnerUserId
), CombinedData AS (
    SELECT 
        U.DisplayName,
        COALESCE(R.RecentPostsCount, 0) AS RecentPostsCount,
        COALESCE(B.BadgesCount, 0) AS BadgesCount,
        U.ReputationRank
    FROM HighReputationUsers U
    LEFT JOIN RecentPostCounts R ON U.UserId = R.OwnerUserId
    LEFT JOIN (
        SELECT 
            UserId,
            COUNT(*) AS BadgesCount
        FROM Badges
        GROUP BY UserId
    ) B ON U.UserId = B.UserId
)
SELECT 
    CD.DisplayName,
    CD.RecentPostsCount,
    CD.BadgesCount,
    CASE 
        WHEN CD.RecentPostsCount = 0 THEN 'No posts in the last 30 days'
        ELSE 'Active user'
    END AS ActivityStatus,
    (SELECT STRING_AGG(T.TagName, ', ') 
     FROM Tags T 
     WHERE T.WikiPostId IS NOT NULL) AS PopularTags,
    (SELECT COUNT(*) 
     FROM Votes V 
     WHERE V.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '7 days' 
     AND V.VoteTypeId = 2) AS RecentUpVotes,
    (SELECT COUNT(*) 
     FROM PostHistory PH 
     WHERE PH.UserId IN (SELECT U.Id 
                         FROM Users U 
                         WHERE U.Reputation > 1000) 
     AND PH.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '90 days') AS HistoryCommentsFromHighReputationUsers
FROM CombinedData CD
GROUP BY CD.DisplayName, CD.RecentPostsCount, CD.BadgesCount, CD.ReputationRank
ORDER BY CD.ReputationRank;

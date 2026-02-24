
WITH UserActivity AS (
    SELECT U.Id AS UserId,
           U.DisplayName,
           U.Reputation,
           COUNT(DISTINCT P.Id) AS PostCount,
           SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
           SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
           SUM(CASE WHEN UP.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
           SUM(CASE WHEN UP.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users U 
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId 
    LEFT JOIN Votes UP ON P.Id = UP.PostId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
RecentPostActivity AS (
    SELECT P.OwnerUserId,
           COUNT(*) AS RecentPosts,
           MAX(P.CreationDate) AS LastPostDate
    FROM Posts P
    WHERE P.CreationDate > (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days')
    GROUP BY P.OwnerUserId
),
AverageScores AS (
    SELECT P.OwnerUserId,
           AVG(P.Score) AS AvgScore
    FROM Posts P
    GROUP BY P.OwnerUserId
),
ActiveUsers AS (
    SELECT UA.*, 
           COALESCE(RPA.RecentPosts, 0) AS RecentPosts,
           COALESCE(RPA.LastPostDate, '1970-01-01'::DATE) AS LastPostDate,
           COALESCE(AScores.AvgScore, 0) AS AvgScore
    FROM UserActivity UA
    LEFT JOIN RecentPostActivity RPA ON UA.UserId = RPA.OwnerUserId
    LEFT JOIN AverageScores AScores ON UA.UserId = AScores.OwnerUserId
)
SELECT U.UserId,
       U.DisplayName,
       U.Reputation,
       U.PostCount,
       U.QuestionCount,
       U.AnswerCount,
       U.UpVotes,
       U.DownVotes,
       U.RecentPosts,
       U.LastPostDate,
       U.AvgScore,
       CASE 
           WHEN U.Reputation > 1000 THEN 'Experienced' 
           WHEN U.Reputation BETWEEN 500 AND 1000 THEN 'Moderate' 
           ELSE 'Beginner' 
       END AS UserLevel
FROM ActiveUsers U
WHERE U.RecentPosts > 5
ORDER BY U.Reputation DESC, U.LastPostDate DESC;

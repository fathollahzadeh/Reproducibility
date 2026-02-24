WITH UserReputation AS (
    SELECT U.Id AS UserId, 
           U.DisplayName, 
           U.Reputation,
           COUNT(DISTINCT P.Id) AS PostCount,
           SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
           SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
           SUM(V.BountyAmount) AS TotalBounty
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9)
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
ActiveUsers AS (
    SELECT UserId, DisplayName, Reputation, PostCount, 
           RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM UserReputation
    WHERE PostCount > 0
),
HighReputationUsers AS (
    SELECT UserId, DisplayName, Reputation, PostCount, ReputationRank
    FROM ActiveUsers
    WHERE ReputationRank <= 10
),
TopTags AS (
    SELECT T.TagName, 
           COUNT(P.Id) AS UsageCount
    FROM Tags T
    JOIN Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY T.TagName
    ORDER BY UsageCount DESC
    LIMIT 5
),
UserTagStats AS (
    SELECT U.DisplayName, 
           T.TagName, 
           COUNT(P.Id) AS TagUsage
    FROM HighReputationUsers U
    JOIN Posts P ON U.UserId = P.OwnerUserId
    JOIN Tags T ON P.Tags LIKE '%' || T.TagName || '%'
    WHERE T.TagName IN (SELECT TagName FROM TopTags)
    GROUP BY U.DisplayName, T.TagName
)
SELECT U.DisplayName, 
       U.Reputation, 
       U.PostCount, 
       T.TagName, 
       COALESCE(SUM(UT.TagUsage), 0) AS TagsUsed
FROM HighReputationUsers U
JOIN TopTags T ON TRUE
LEFT JOIN UserTagStats UT ON U.DisplayName = UT.DisplayName AND T.TagName = UT.TagName
GROUP BY U.DisplayName, U.Reputation, U.PostCount, T.TagName
ORDER BY U.Reputation DESC, T.TagName;

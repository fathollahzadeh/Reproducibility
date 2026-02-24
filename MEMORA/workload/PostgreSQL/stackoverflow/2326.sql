
WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(U.Reputation) AS AvgReputation
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName
),
TopTags AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount
    FROM Tags T
    JOIN Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY T.TagName
    ORDER BY PostCount DESC
    LIMIT 10
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBountyAmount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank,
        P.OwnerUserId
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9) 
    GROUP BY P.Id, P.Title, P.CreationDate
)
SELECT 
    UPS.UserId,
    UPS.DisplayName,
    UPS.TotalPosts,
    UPS.TotalQuestions,
    UPS.TotalAnswers,
    UPS.AvgReputation,
    PT.PostId,
    PT.Title,
    PT.CreationDate,
    PT.TotalBountyAmount,
    T.TagName
FROM UserPostStats UPS
JOIN PostDetails PT ON UPS.UserId = PT.OwnerUserId
LEFT JOIN TopTags T ON PT.Title LIKE '%' || T.TagName || '%'
WHERE UPS.TotalPosts > 5
  AND PT.PostRank = 1
  AND PT.TotalBountyAmount > 0
  AND PT.CreationDate BETWEEN TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' AND TIMESTAMP '2024-10-01 12:34:56'
ORDER BY UPS.AvgReputation DESC, PT.TotalBountyAmount DESC;

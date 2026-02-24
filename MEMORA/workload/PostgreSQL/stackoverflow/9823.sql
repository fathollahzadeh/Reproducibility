WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(V.BountyAmount) AS TotalBounty,
        COALESCE(MAX(P.LastActivityDate), '1970-01-01') AS LastActive
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        QuestionCount,
        AnswerCount,
        TotalBounty,
        LastActive,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC, PostCount DESC) AS Rank
    FROM UserStats
),
ActiveUsers AS (
    SELECT 
        *
    FROM TopUsers
    WHERE LastActive >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
)
SELECT 
    AU.DisplayName,
    AU.Reputation,
    AU.PostCount,
    AU.QuestionCount,
    AU.AnswerCount,
    AU.TotalBounty,
    AU.Rank,
    p.Title AS RecentPostTitle,
    p.CreationDate AS RecentPostDate,
    p.ViewCount AS RecentPostViews,
    p.Score AS RecentPostScore
FROM ActiveUsers AU
LEFT JOIN Posts p ON AU.UserId = p.OwnerUserId
WHERE p.CreationDate = (
    SELECT MAX(CreationDate) 
    FROM Posts 
    WHERE OwnerUserId = AU.UserId
)
ORDER BY AU.Rank
LIMIT 10;
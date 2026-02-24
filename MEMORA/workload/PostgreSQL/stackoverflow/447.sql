
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.Views,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(V.BountyAmount) AS TotalBounty
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY U.Id, U.DisplayName, U.Reputation, U.Views
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        Views,
        PostCount,
        AnswerCount,
        TotalBounty,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM UserStats
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    TU.Views,
    TU.PostCount,
    TU.AnswerCount,
    COALESCE(B.Name, 'No Badge') AS Badge,
    CASE 
        WHEN TU.TotalBounty > 100 THEN 'High Bounty Contributor'
        ELSE 'Regular Contributor' 
    END AS ContributorType
FROM TopUsers TU
LEFT JOIN Badges B ON TU.UserId = B.UserId AND B.Class = 1
WHERE TU.Rank <= 10
ORDER BY TU.Rank;

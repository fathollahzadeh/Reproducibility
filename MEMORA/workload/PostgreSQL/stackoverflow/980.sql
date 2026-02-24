WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.Views,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END, 0)) AS Questions,
        SUM(COALESCE(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END, 0)) AS Answers,
        AVG(V.BountyAmount) AS AvgBounty
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId = 8
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.Views
),
ActiveUsers AS (
    SELECT 
        UA.*,
        ROW_NUMBER() OVER (ORDER BY UA.Reputation DESC) AS UserRank
    FROM 
        UserActivity UA
    WHERE 
        UA.Views > 1000
),
TopUsers AS (
    SELECT 
        U.*,
        COALESCE(B.Name, 'No Badge') AS BadgeName
    FROM 
        ActiveUsers U
    LEFT JOIN 
        Badges B ON U.UserId = B.UserId
    WHERE 
        U.UserRank <= 10
)
SELECT 
    T.DisplayName,
    T.Reputation,
    T.PostCount,
    T.Questions,
    T.Answers,
    T.AvgBounty,
    STRING_AGG(DISTINCT CASE WHEN T.BadgeName <> 'No Badge' THEN T.BadgeName END, ', ') AS Badges
FROM 
    TopUsers T
LEFT JOIN 
    PostHistory PH ON T.UserId = PH.UserId
WHERE 
    PH.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
GROUP BY 
    T.UserId, T.DisplayName, T.Reputation, T.PostCount, T.Questions, T.Answers, T.AvgBounty
HAVING 
    COUNT(PH.Id) >= 5
ORDER BY 
    T.Reputation DESC
LIMIT 10;
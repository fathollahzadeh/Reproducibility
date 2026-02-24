
WITH UserMetrics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        SUM(CASE WHEN P.Score IS NOT NULL THEN 1 ELSE 0 END) AS TotalPosts,
        SUM(CASE WHEN P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalPosts,
        AcceptedAnswers,
        TotalViews,
        TotalUpvotes,
        TotalDownvotes,
        DENSE_RANK() OVER (ORDER BY Reputation DESC) AS UserRank
    FROM 
        UserMetrics
)
SELECT 
    TU.UserId,
    TU.DisplayName,
    TU.Reputation,
    TU.TotalPosts,
    TU.AcceptedAnswers,
    TU.TotalViews,
    TU.TotalUpvotes,
    TU.TotalDownvotes,
    THH.HistoricalRevisions
FROM 
    TopUsers TU
JOIN 
    (SELECT 
        P.OwnerUserId,
        COUNT(PH.Id) AS HistoricalRevisions
     FROM 
        Posts P
     JOIN 
        PostHistory PH ON P.Id = PH.PostId
     GROUP BY 
        P.OwnerUserId) THH ON TU.UserId = THH.OwnerUserId
WHERE 
    TU.UserRank <= 10
ORDER BY 
    TU.UserRank;

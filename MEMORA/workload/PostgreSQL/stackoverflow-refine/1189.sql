WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(P.Id) AS TotalPosts,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalAnswers,
        COALESCE(SUM(CASE WHEN P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END), 0) AS AcceptedAnswers,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
RecentActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(C.Id) AS TotalComments,
        MAX(C.CreationDate) AS LastCommentDate
    FROM 
        Users U
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    GROUP BY 
        U.Id, U.DisplayName
)
SELECT 
    UPS.UserId,
    UPS.DisplayName,
    UPS.Reputation,
    UPS.TotalPosts,
    UPS.TotalAnswers,
    UPS.AcceptedAnswers,
    UPS.ReputationRank,
    RA.TotalComments,
    RA.LastCommentDate
FROM 
    UserPostStats UPS
FULL OUTER JOIN 
    RecentActivity RA ON UPS.UserId = RA.UserId
WHERE 
    (UPS.Reputation > 100 OR RA.TotalComments > 5)
    AND (UPS.TotalPosts IS NOT NULL OR RA.TotalComments IS NOT NULL)
ORDER BY 
    UPS.ReputationRank ASC NULLS LAST, UPS.TotalPosts DESC NULLS LAST;


WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        ROW_NUMBER() OVER(ORDER BY SUM(COALESCE(P.Score, 0)) DESC) AS ActivityRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
), 
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        TotalViews,
        TotalScore
    FROM 
        UserActivity
    WHERE 
        ActivityRank <= 10
), 
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.LastActivityDate,
        CASE 
            WHEN P.AcceptedAnswerId IS NOT NULL THEN 'Yes' 
            ELSE 'No' 
        END AS HasAcceptedAnswer,
        COALESCE(P.Score, 0) AS Score,
        COALESCE(COUNT(C.Id), 0) AS CommentCount,
        P.ViewCount,
        P.OwnerUserId
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.LastActivityDate, P.AcceptedAnswerId, P.Score, P.ViewCount, P.OwnerUserId
)
SELECT 
    TU.DisplayName,
    P.Title AS PostTitle,
    P.CreationDate,
    P.LastActivityDate,
    P.HasAcceptedAnswer,
    P.Score,
    P.CommentCount,
    P.ViewCount
FROM 
    TopUsers TU
INNER JOIN 
    PostStatistics P ON TU.UserId = P.OwnerUserId
ORDER BY 
    TU.TotalScore DESC, P.Score DESC;

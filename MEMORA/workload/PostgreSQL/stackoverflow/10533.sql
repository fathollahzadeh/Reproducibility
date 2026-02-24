WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(C.CommentCount, 0)) AS TotalComments
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN (
        SELECT PostId, COUNT(Id) AS CommentCount
        FROM Comments
        GROUP BY PostId
    ) C ON P.Id = C.PostId
    WHERE U.CreationDate >= '2022-01-01' 
    GROUP BY U.Id, U.Reputation
),
PostTypesStats AS (
    SELECT 
        PT.Id AS PostTypeId,
        PT.Name AS PostTypeName,
        COUNT(P.Id) AS PostCount,
        SUM(P.Score) AS TotalScore,
        SUM(P.ViewCount) AS TotalViews
    FROM PostTypes PT
    LEFT JOIN Posts P ON PT.Id = P.PostTypeId
    GROUP BY PT.Id, PT.Name
)
SELECT 
    U.UserId,
    U.Reputation,
    U.PostCount AS UserPostCount,
    U.TotalScore AS UserTotalScore,
    U.TotalViews AS UserTotalViews,
    U.TotalComments AS UserTotalComments,
    PT.PostTypeId,
    PT.PostTypeName,
    PT.PostCount AS PostTypePostCount,
    PT.TotalScore AS PostTypeTotalScore,
    PT.TotalViews AS PostTypeTotalViews
FROM UserStats U
JOIN PostTypesStats PT ON U.PostCount > 0
ORDER BY U.Reputation DESC, PT.TotalViews DESC;
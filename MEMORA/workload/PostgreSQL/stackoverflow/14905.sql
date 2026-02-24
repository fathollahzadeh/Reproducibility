WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN P.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        AVG(V.BountyAmount) AS AverageBounty
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId = 8 
    GROUP BY 
        U.Id, U.DisplayName
),
PostTypesStats AS (
    SELECT 
        PT.Name AS PostTypeName,
        COUNT(P.Id) AS PostCount,
        AVG(P.Score) AS AverageScore,
        AVG(P.ViewCount) AS AverageViewCount
    FROM 
        Posts P
    JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
    GROUP BY 
        PT.Name
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.PostCount,
    U.PositivePosts,
    U.NegativePosts,
    U.AverageBounty,
    PTS.PostTypeName,
    PTS.PostCount AS TotalPostsByType,
    PTS.AverageScore,
    PTS.AverageViewCount
FROM 
    UserStats U
JOIN 
    PostTypesStats PTS ON PTS.PostCount > 0
ORDER BY 
    U.PostCount DESC, 
    PTS.PostTypeName;
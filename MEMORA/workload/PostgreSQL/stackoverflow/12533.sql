
WITH PostStatistics AS (
    SELECT 
        PT.Name AS PostType,
        COUNT(P.Id) AS PostCount,
        AVG(P.Score) AS AverageScore,
        AVG(P.ViewCount) AS AverageViewCount,
        SUM(CASE WHEN V.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalVotes,
        AVG(U.Reputation) AS AverageUserReputation
    FROM 
        Posts P
    LEFT JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    GROUP BY 
        PT.Name
)

SELECT 
    PostType,
    PostCount,
    AverageScore,
    AverageViewCount,
    TotalVotes,
    AverageUserReputation
FROM 
    PostStatistics
ORDER BY 
    PostCount DESC;

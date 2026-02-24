WITH PostStats AS (
    SELECT 
        P.PostTypeId,
        COUNT(*) AS TotalPosts,
        AVG(COALESCE(P.Score, 0)) AS AvgScore
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= '2023-01-01' 
    GROUP BY 
        P.PostTypeId
),
UserStats AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount,
        AVG(U.Reputation) AS AvgReputation
    FROM
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
)

SELECT 
    CASE 
        WHEN PS.PostTypeId = 1 THEN 'Question'
        WHEN PS.PostTypeId = 2 THEN 'Answer'
        ELSE 'Other'
    END AS PostType,
    PS.TotalPosts,
    PS.AvgScore,
    COUNT(DISTINCT US.UserId) AS UniqueUsers,
    AVG(US.AvgReputation) AS AvgUserReputation,
    SUM(US.BadgeCount) AS TotalBadges
FROM 
    PostStats PS
LEFT JOIN 
    Posts P ON P.PostTypeId = PS.PostTypeId
LEFT JOIN 
    UserStats US ON P.OwnerUserId = US.UserId
GROUP BY 
    PS.PostTypeId, PS.TotalPosts, PS.AvgScore
ORDER BY 
    PS.PostTypeId;
WITH PostCounts AS (
    SELECT 
        PostTypeId, 
        COUNT(*) AS TotalPosts
    FROM 
        Posts
    GROUP BY 
        PostTypeId
),
TopUsers AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        COUNT(P.Id) AS PostCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
BadgeCounts AS (
    SELECT 
        UserId,
        COUNT(*) AS TotalBadges
    FROM 
        Badges
    GROUP BY 
        UserId
)

SELECT 
    PCT.PostTypeId,
    PCT.TotalPosts,
    TU.DisplayName AS TopUser,
    TU.PostCount AS UserPostCount,
    TU.TotalScore AS UserTotalScore,
    BC.TotalBadges AS UserTotalBadges
FROM 
    PostCounts PCT
JOIN 
    TopUsers TU ON TU.PostCount = (SELECT MAX(PostCount) FROM TopUsers)
JOIN 
    BadgeCounts BC ON TU.UserId = BC.UserId
ORDER BY 
    PCT.TotalPosts DESC;
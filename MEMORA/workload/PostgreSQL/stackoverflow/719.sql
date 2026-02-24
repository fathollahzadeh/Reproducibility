WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN P.OwnerUserId IS NOT NULL THEN 1 ELSE 0 END) AS TotalPosts,
        SUM(CASE WHEN C.UserId IS NOT NULL THEN 1 ELSE 0 END) AS TotalComments,
        SUM(CASE WHEN B.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalBadges,
        COALESCE(AVG(P.ViewCount), 0) AS AvgViewCount,
        RANK() OVER (ORDER BY SUM(P.Score) DESC) AS ScoreRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    WHERE 
        U.Reputation > 0
    GROUP BY 
        U.Id, U.DisplayName
), 
BadgedUsers AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges
    GROUP BY 
        UserId
)
SELECT 
    UA.UserId,
    UA.DisplayName,
    UA.TotalPosts,
    UA.TotalComments,
    COALESCE(BU.BadgeCount, 0) AS BadgeCount,
    UA.AvgViewCount,
    UA.ScoreRank,
    CASE 
        WHEN UA.ScoreRank <= 10 THEN 'Top User'
        WHEN UA.ScoreRank <= 50 THEN 'Active User'
        ELSE 'New User'
    END AS UserCategory
FROM 
    UserActivity UA
LEFT JOIN 
    BadgedUsers BU ON UA.UserId = BU.UserId
ORDER BY 
    UA.ScoreRank
OFFSET 10 ROWS FETCH NEXT 20 ROWS ONLY;

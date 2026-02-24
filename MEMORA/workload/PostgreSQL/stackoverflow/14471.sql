WITH PostCounts AS (
    SELECT 
        PostTypeId, 
        COUNT(*) AS TotalPosts
    FROM 
        Posts
    GROUP BY 
        PostTypeId
),
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
)
SELECT 
    PCT.PostTypeId,
    PCT.TotalPosts,
    UA.UserId,
    UA.DisplayName,
    UA.PostCount,
    UA.Questions,
    UA.Answers
FROM 
    PostCounts PCT
JOIN 
    UserActivity UA ON UA.PostCount > 0
ORDER BY 
    PCT.PostTypeId, UA.PostCount DESC;
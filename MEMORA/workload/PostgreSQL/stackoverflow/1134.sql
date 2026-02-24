WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounty,
        RANK() OVER (ORDER BY COUNT(P.Id) DESC) AS ActivityRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9) 
    GROUP BY 
        U.Id, U.DisplayName
),

PopularPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        ROW_NUMBER() OVER (ORDER BY P.Score DESC, P.ViewCount DESC) AS PopularityRank
    FROM 
        Posts P
    WHERE 
        P.CreationDate > (cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days')
)

SELECT 
    UA.DisplayName,
    UA.TotalPosts,
    UA.QuestionCount,
    UA.AnswerCount,
    UA.TotalBounty,
    PP.Title AS PopularPostTitle,
    PP.CreationDate AS PopularPostDate,
    PP.Score AS PopularPostScore
FROM 
    UserActivity UA
LEFT JOIN 
    PopularPosts PP ON UA.QuestionCount > 0
WHERE 
    UA.ActivityRank <= 10
ORDER BY 
    UA.TotalPosts DESC, UA.TotalBounty DESC;
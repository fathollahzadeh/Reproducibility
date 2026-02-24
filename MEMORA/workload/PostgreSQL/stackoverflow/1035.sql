WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(COALESCE(C.CommentsCount, 0)) AS TotalComments,
        SUM(U.UpVotes) AS TotalUpVotes,
        SUM(U.DownVotes) AS TotalDownVotes,
        ROW_NUMBER() OVER (ORDER BY SUM(U.UpVotes) - SUM(U.DownVotes) DESC) AS Rank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN (
        SELECT 
            C.PostId,
            COUNT(C.Id) AS CommentsCount
        FROM 
            Comments C
        GROUP BY 
            C.PostId
    ) C ON P.Id = C.PostId
    GROUP BY 
        U.Id, U.DisplayName
),

PostRank AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        DENSE_RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS ScoreRank,
        ROW_NUMBER() OVER (ORDER BY P.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
)

SELECT 
    UA.DisplayName,
    UA.TotalPosts,
    UA.TotalQuestions,
    UA.TotalAnswers,
    UA.TotalComments,
    UA.TotalUpVotes,
    UA.TotalDownVotes,
    PR.PostId,
    PR.Title,
    PR.CreationDate,
    PR.ViewCount,
    PR.Score,
    PR.ScoreRank,
    PR.RecentPostRank
FROM 
    UserActivity UA
LEFT JOIN 
    PostRank PR ON UA.UserId = PR.PostId
WHERE 
    (UA.TotalQuestions > 0 OR UA.TotalAnswers > 0)
    AND UA.TotalUpVotes > 5
ORDER BY 
    UA.Rank, PR.Score DESC
LIMIT 100;

WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.UserId = U.Id
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        T.TagName,
        P.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
    JOIN 
        Tags T ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        UserStats.UserId,
        UserStats.DisplayName,
        UserStats.Reputation,
        COUNT(PostDetails.PostId) AS PostsInLastYear,
        SUM(PostDetails.Score) AS TotalScore,
        SUM(PostDetails.ViewCount) AS TotalViews
    FROM 
        UserStats
    JOIN 
        PostDetails ON UserStats.UserId = PostDetails.OwnerUserId
    GROUP BY 
        UserStats.UserId, UserStats.DisplayName, UserStats.Reputation
)
SELECT 
    U.DisplayName,
    U.Reputation,
    T.PostsInLastYear,
    T.TotalScore,
    T.TotalViews
FROM 
    UserStats U
JOIN 
    TopPosts T ON U.UserId = T.UserId
WHERE 
    T.PostsInLastYear > 5
ORDER BY 
    T.TotalScore DESC, U.Reputation DESC
LIMIT 10;

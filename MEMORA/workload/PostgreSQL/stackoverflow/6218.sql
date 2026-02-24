
WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        U.Reputation > 100
    GROUP BY 
        U.Id, U.DisplayName
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        U.DisplayName AS OwnerDisplayName,
        COUNT(C.Id) AS TotalComments
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.CreationDate >= '2020-01-01'
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.ViewCount, P.Score, U.DisplayName
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        CreationDate, 
        ViewCount, 
        Score, 
        OwnerDisplayName, 
        TotalComments,
        ROW_NUMBER() OVER (ORDER BY ViewCount DESC) AS Rank
    FROM 
        PostStatistics
)
SELECT 
    U.*,
    T.Title AS TopPostTitle,
    T.ViewCount AS TopPostViews,
    T.Score AS TopPostScore,
    T.TotalComments AS TopPostComments
FROM 
    UserVoteStats U
LEFT JOIN 
    TopPosts T ON U.UserId = (SELECT OwnerUserId FROM Posts ORDER BY Score DESC LIMIT 1)
WHERE 
    U.TotalUpvotes > U.TotalDownvotes
ORDER BY 
    U.TotalUpvotes DESC;

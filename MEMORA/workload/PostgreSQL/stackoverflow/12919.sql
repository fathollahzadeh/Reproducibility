
WITH Benchmark AS (
    SELECT 
        P.Id AS PostId,
        U.DisplayName AS OwnerDisplayName,
        P.Title,
        P.CreationDate,
        P.LastEditDate,
        P.ViewCount,
        P.Score,
        COUNT(C.Id) AS CommentCount,
        COUNT(V.Id) AS VoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, U.DisplayName, P.Title, P.CreationDate, P.LastEditDate, P.ViewCount, P.Score
)

SELECT 
    COUNT(*) AS TotalPosts,
    AVG(ViewCount) AS AverageViews,
    AVG(Score) AS AverageScore,
    SUM(CommentCount) AS TotalComments,
    SUM(VoteCount) AS TotalVotes
FROM 
    Benchmark;

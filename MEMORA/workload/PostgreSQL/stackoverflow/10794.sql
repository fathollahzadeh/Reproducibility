WITH UserVoteStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
TopPosts AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1 
    ORDER BY 
        P.Score DESC, P.ViewCount DESC
    LIMIT 10
)

SELECT 
    U.DisplayName,
    U.TotalVotes,
    U.UpVotes,
    U.DownVotes,
    T.Title AS TopPostTitle,
    T.Score AS TopPostScore,
    T.ViewCount AS TopPostViews,
    T.AnswerCount AS TopPostAnswers,
    T.CommentCount AS TopPostComments
FROM 
    UserVoteStatistics U
JOIN 
    TopPosts T ON T.PostId IN (SELECT P.Id FROM Posts P WHERE P.OwnerUserId = U.UserId)
ORDER BY 
    U.TotalVotes DESC
LIMIT 10;

WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesCount,
        COUNT(DISTINCT P.Id) AS PostsCount,
        SUM(P.Score) AS TotalScore
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        UpVotesCount,
        DownVotesCount,
        PostsCount,
        TotalScore,
        RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank
    FROM UserReputation
),
PopularPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COUNT(C) AS CommentCount,
        ROW_NUMBER() OVER (ORDER BY P.Score DESC, P.ViewCount DESC) AS PostRank
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    WHERE P.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '30 days'
    GROUP BY P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount
)

SELECT 
    U.UserId,
    U.DisplayName,
    U.UpVotesCount,
    U.DownVotesCount,
    U.PostsCount,
    U.TotalScore,
    P.PostId,
    P.Title AS PopularPostTitle,
    P.Score AS PopularPostScore,
    P.ViewCount AS PopularPostViewCount,
    P.CommentCount AS PopularPostCommentCount
FROM TopUsers U
FULL OUTER JOIN PopularPosts P ON U.ScoreRank = 1 AND P.PostRank <= 5
WHERE U.PostsCount > 10 OR P.CommentCount IS NOT NULL
ORDER BY U.TotalScore DESC, P.Score DESC;

WITH UserVoteSummary AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS Downvotes,
        COUNT(CASE WHEN V.VoteTypeId = 6 THEN 1 END) AS CloseVotes,
        COUNT(CASE WHEN V.VoteTypeId = 7 THEN 1 END) AS ReopenVotes
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        P.FavoriteCount,
        U.DisplayName AS OwnerDisplayName,
        RANK() OVER (ORDER BY P.Score DESC) AS ScoreRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1 
        AND P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.Score,
        PS.OwnerDisplayName,
        US.Upvotes AS TotalUpvotes,
        US.Downvotes AS TotalDownvotes,
        US.CloseVotes AS TotalCloseVotes,
        US.ReopenVotes AS TotalReopenVotes
    FROM 
        PostStatistics PS
    JOIN 
        UserVoteSummary US ON US.UserId IN (
            SELECT DISTINCT U.Id 
            FROM Votes V 
            JOIN Posts P ON V.PostId = P.Id 
            JOIN Users U ON U.Id = P.OwnerUserId 
            WHERE P.Id = PS.PostId
        )
    WHERE 
        PS.ScoreRank <= 10
)
SELECT 
    TP.PostId,
    TP.Title,
    TP.Score,
    TP.OwnerDisplayName,
    TP.TotalUpvotes,
    TP.TotalDownvotes,
    TP.TotalCloseVotes,
    TP.TotalReopenVotes,
    (TP.TotalUpvotes - TP.TotalDownvotes) AS NetVotes
FROM 
    TopPosts TP
ORDER BY 
    TP.Score DESC, 
    NetVotes DESC;
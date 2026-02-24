
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId, 
        P.Title, 
        U.DisplayName AS OwnerDisplayName,
        P.CreationDate, 
        P.Score, 
        P.ViewCount, 
        P.AnswerCount, 
        P.CommentCount, 
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS RankByScore
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
), 
TopPosts AS (
    SELECT PostId, Title, OwnerDisplayName, CreationDate, Score, ViewCount, AnswerCount, CommentCount
    FROM RankedPosts
    WHERE RankByScore <= 10
), 
UserStats AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT PH.PostId) AS PostsEdited
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        PostHistory PH ON U.Id = PH.UserId
    GROUP BY 
        U.Id, U.DisplayName
)
SELECT 
    TP.PostId, 
    TP.Title, 
    TP.OwnerDisplayName, 
    TP.CreationDate, 
    TP.Score, 
    TP.ViewCount,
    TP.AnswerCount, 
    TP.CommentCount,
    US.DisplayName AS EditorDisplayName, 
    US.UpVotes, 
    US.DownVotes, 
    US.PostsEdited
FROM 
    TopPosts TP
LEFT JOIN 
    UserStats US ON TP.OwnerDisplayName = US.DisplayName
ORDER BY 
    TP.Score DESC, 
    TP.ViewCount DESC;

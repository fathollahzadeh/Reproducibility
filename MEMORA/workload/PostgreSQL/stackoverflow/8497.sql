WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC, P.ViewCount DESC) AS RankScore
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
        AND P.PostTypeId IN (1, 2) 
),
TopPosts AS (
    SELECT 
        PostId, Title, CreationDate, Score, ViewCount, AnswerCount, CommentCount, OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        RankScore <= 10
),
VoteSummary AS (
    SELECT 
        PostId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes V
    GROUP BY 
        PostId
)
SELECT 
    TP.Title,
    TP.CreationDate,
    TP.Score,
    TP.ViewCount,
    TP.AnswerCount,
    TP.CommentCount,
    TP.OwnerDisplayName,
    COALESCE(VS.UpVotes, 0) AS TotalUpVotes,
    COALESCE(VS.DownVotes, 0) AS TotalDownVotes
FROM 
    TopPosts TP
LEFT JOIN 
    VoteSummary VS ON TP.PostId = VS.PostId
ORDER BY 
    TP.Score DESC, TP.ViewCount DESC;
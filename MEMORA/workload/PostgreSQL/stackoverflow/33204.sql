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
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS PostRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        OwnerDisplayName,
        Score,
        ViewCount,
        AnswerCount,
        CommentCount
    FROM 
        RankedPosts
    WHERE 
        PostRank <= 10 
),
PostComments AS (
    SELECT 
        C.PostId,
        COUNT(C.Id) AS TotalComments,
        STRING_AGG(C.Text, ' | ' ORDER BY C.CreationDate) AS CommentsText
    FROM 
        Comments C
    GROUP BY 
        C.PostId
),
PostVoteSummary AS (
    SELECT 
        P.Id AS PostId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id
)
SELECT 
    TP.Title,
    TP.OwnerDisplayName,
    TP.Score,
    TP.ViewCount,
    TP.AnswerCount,
    TP.CommentCount,
    COALESCE(PC.TotalComments, 0) AS TotalComments,
    COALESCE(PC.CommentsText, 'No comments') AS CommentsText,
    COALESCE(PVS.UpVotes, 0) AS UpVotes,
    COALESCE(PVS.DownVotes, 0) AS DownVotes
FROM 
    TopPosts TP
LEFT JOIN 
    PostComments PC ON TP.PostId = PC.PostId
LEFT JOIN 
    PostVoteSummary PVS ON TP.PostId = PVS.PostId
WHERE 
    TP.Score > 0 
ORDER BY 
    TP.Score DESC, TP.ViewCount DESC;
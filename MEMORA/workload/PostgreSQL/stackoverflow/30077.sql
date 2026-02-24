WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.AcceptedAnswerId,
        U.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS Rank
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
        AND P.Score IS NOT NULL
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        CreationDate,
        Score,
        ViewCount,
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
),
VoteAggregates AS (
    SELECT 
        PostId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes V
    GROUP BY 
        PostId
),
CommentsSummary AS (
    SELECT 
        C.PostId,
        COUNT(*) AS CommentCount,
        MAX(C.CreationDate) AS LastCommentDate
    FROM 
        Comments C
    GROUP BY 
        C.PostId
)
SELECT 
    TP.Title,
    TP.OwnerDisplayName,
    TP.CreationDate,
    TP.Score,
    COALESCE(VA.UpVotes, 0) AS UpVotes,
    COALESCE(VA.DownVotes, 0) AS DownVotes,
    COALESCE(CS.CommentCount, 0) AS CommentCount,
    CS.LastCommentDate
FROM 
    TopPosts TP
LEFT JOIN 
    VoteAggregates VA ON TP.PostId = VA.PostId
LEFT JOIN 
    CommentsSummary CS ON TP.PostId = CS.PostId
ORDER BY 
    TP.Score DESC, TP.CreationDate ASC;
WITH PostSummary AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.AnswerCount,
        U.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.PostTypeId = 1 AND 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.ViewCount, P.AnswerCount, U.DisplayName
),
TopPosts AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY UpVoteCount DESC, AnswerCount DESC, ViewCount DESC) AS PostRank
    FROM 
        PostSummary
)
SELECT 
    PostId, 
    Title, 
    CreationDate, 
    ViewCount, 
    AnswerCount, 
    OwnerDisplayName, 
    CommentCount, 
    UpVoteCount, 
    DownVoteCount
FROM 
    TopPosts
WHERE 
    PostRank <= 10;
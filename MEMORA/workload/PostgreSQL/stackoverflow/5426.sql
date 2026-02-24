WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        U.DisplayName AS OwnerDisplayName,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpvoteCount,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownvoteCount,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COALESCE(SUM(CASE WHEN P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END), 0) AS AcceptedAnswerCount
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.OwnerUserId, U.DisplayName
),
TopPosts AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.CreationDate,
        PS.OwnerDisplayName,
        PS.UpvoteCount,
        PS.DownvoteCount,
        PS.CommentCount,
        PS.AcceptedAnswerCount,
        ROW_NUMBER() OVER (ORDER BY PS.UpvoteCount DESC) AS Rank
    FROM 
        PostStats PS
)
SELECT 
    T.Title,
    T.OwnerDisplayName,
    T.UpvoteCount,
    T.DownvoteCount,
    T.CommentCount,
    T.AcceptedAnswerCount
FROM 
    TopPosts T
WHERE 
    T.Rank <= 10
ORDER BY 
    T.UpvoteCount DESC;
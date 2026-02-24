WITH PostMetrics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.Score,
        P.CreationDate,
        COALESCE(UPVotes, 0) AS UpVotes,
        COALESCE(DownVotes, 0) AS DownVotes,
        COUNT(C.Id) AS CommentCount,
        COUNT(V.Id) AS VoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    GROUP BY 
        P.Id, P.Title, P.ViewCount, P.Score, P.CreationDate, U.UpVotes, U.DownVotes
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        ViewCount, 
        Score, 
        CreationDate, 
        UpVotes, 
        DownVotes, 
        CommentCount, 
        VoteCount,
        ROW_NUMBER() OVER (ORDER BY Score DESC, ViewCount DESC) AS Ranked
    FROM 
        PostMetrics
)
SELECT 
    PostId,
    Title,
    ViewCount,
    Score,
    CreationDate,
    UpVotes,
    DownVotes,
    CommentCount,
    VoteCount
FROM 
    TopPosts
WHERE 
    Ranked <= 100;
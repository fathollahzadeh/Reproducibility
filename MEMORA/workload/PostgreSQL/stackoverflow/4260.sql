WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        U.Reputation,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS Rank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        Reputation
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
),
PostVotes AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(VoteTypeId) AS TotalVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
PostComments AS (
    SELECT 
        PostId,
        COUNT(*) AS CommentCount
    FROM 
        Comments
    GROUP BY 
        PostId
)
SELECT 
    TP.PostId,
    TP.Title,
    TP.CreationDate,
    COALESCE(PV.UpVotes, 0) AS UpVotes,
    COALESCE(PV.DownVotes, 0) AS DownVotes,
    COALESCE(PC.CommentCount, 0) AS CommentCount,
    TP.Score,
    TP.ViewCount,
    TP.Reputation
FROM 
    TopPosts TP
LEFT JOIN 
    PostVotes PV ON TP.PostId = PV.PostId
LEFT JOIN 
    PostComments PC ON TP.PostId = PC.PostId
WHERE 
    (TP.Score > 10 OR TP.ViewCount > 50) 
    AND (TP.Reputation IS NOT NULL AND TP.Reputation > 100)
ORDER BY 
    TP.Score DESC, TP.ViewCount DESC;
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.Score, 
        p.ViewCount,
        p.CreationDate,
        U.DisplayName AS OwnerName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        Score, 
        ViewCount, 
        OwnerName
    FROM 
        RankedPosts
    WHERE 
        rn <= 5
),
PostVotes AS (
    SELECT 
        V.PostId, 
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes V
    GROUP BY 
        V.PostId
),
PostComments AS (
    SELECT 
        C.PostId, 
        COUNT(C.Id) AS CommentCount
    FROM 
        Comments C
    GROUP BY 
        C.PostId
)
SELECT 
    TP.PostId,
    TP.Title,
    TP.Score,
    TP.ViewCount,
    TP.OwnerName,
    COALESCE(PV.UpVotes, 0) AS TotalUpVotes,
    COALESCE(PV.DownVotes, 0) AS TotalDownVotes,
    COALESCE(PC.CommentCount, 0) AS TotalComments
FROM 
    TopPosts TP
LEFT JOIN 
    PostVotes PV ON TP.PostId = PV.PostId
LEFT JOIN 
    PostComments PC ON TP.PostId = PC.PostId
ORDER BY 
    TP.Score DESC, TP.ViewCount DESC
LIMIT 20;
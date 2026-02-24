WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS Author,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.Author,
        RP.CreationDate,
        RP.Score
    FROM 
        RankedPosts RP
    WHERE 
        RP.Rank <= 5
),
PostComments AS (
    SELECT 
        pc.PostId,
        COUNT(pc.Id) AS CommentCount
    FROM 
        Comments pc
    GROUP BY 
        pc.PostId
),
PostVotes AS (
    SELECT 
        pv.PostId,
        SUM(CASE WHEN pv.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN pv.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes pv
    GROUP BY 
        pv.PostId
)
SELECT 
    TP.Title,
    TP.Author,
    TP.CreationDate,
    COALESCE(PC.CommentCount, 0) AS TotalComments,
    COALESCE(PV.UpVotes, 0) AS TotalUpVotes,
    COALESCE(PV.DownVotes, 0) AS TotalDownVotes,
    (COALESCE(PV.UpVotes, 0) - COALESCE(PV.DownVotes, 0)) AS NetScore
FROM 
    TopPosts TP
LEFT JOIN 
    PostComments PC ON TP.PostId = PC.PostId
LEFT JOIN 
    PostVotes PV ON TP.PostId = PV.PostId
ORDER BY 
    NetScore DESC, TP.CreationDate DESC;
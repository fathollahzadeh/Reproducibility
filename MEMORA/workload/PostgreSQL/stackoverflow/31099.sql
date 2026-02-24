
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
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC, P.CreationDate DESC) AS RankScore
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        AnswerCount,
        CommentCount,
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        RankScore <= 5 
),
PostVoteStats AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes V
    GROUP BY 
        PostId
)
SELECT 
    TP.PostId,
    TP.Title,
    TP.CreationDate,
    TP.Score,
    TP.ViewCount,
    TP.AnswerCount,
    TP.CommentCount,
    TP.OwnerDisplayName,
    COALESCE(PVS.UpVotes, 0) AS UpVotes,
    COALESCE(PVS.DownVotes, 0) AS DownVotes,
    (COALESCE(PVS.UpVotes, 0) - COALESCE(PVS.DownVotes, 0)) AS NetVotes,
    CASE 
        WHEN COALESCE(PVS.UpVotes, 0) + COALESCE(PVS.DownVotes, 0) > 0 
        THEN COALESCE(PVS.UpVotes, 0)::FLOAT / (COALESCE(PVS.UpVotes, 0) + COALESCE(PVS.DownVotes, 0)) * 100 
        ELSE NULL 
    END AS VotePercentage
FROM 
    TopPosts TP
LEFT JOIN 
    PostVoteStats PVS ON TP.PostId = PVS.PostId
ORDER BY 
    TP.Score DESC, 
    TP.CreationDate DESC;

WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        U.Reputation AS OwnerReputation,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC, P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id 
    WHERE 
        P.PostTypeId = 1  
        AND P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
),
TopPosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.CreationDate,
        RP.Score,
        RP.ViewCount,
        RP.OwnerReputation
    FROM 
        RankedPosts RP
    WHERE 
        RP.PostRank = 1  
),
PostVotes AS (
    SELECT 
        V.PostId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes V
    GROUP BY 
        V.PostId
),
PostComments AS (
    SELECT 
        C.PostId,
        COUNT(*) AS CommentCount
    FROM 
        Comments C
    GROUP BY 
        C.PostId
),
FinalResult AS (
    SELECT 
        TP.PostId,
        TP.Title,
        TP.CreationDate,
        TP.Score,
        TP.ViewCount,
        TP.OwnerReputation,
        COALESCE(PV.UpVotes, 0) AS UpVotes,
        COALESCE(PV.DownVotes, 0) AS DownVotes,
        COALESCE(PC.CommentCount, 0) AS CommentCount
    FROM 
        TopPosts TP
    LEFT JOIN 
        PostVotes PV ON TP.PostId = PV.PostId
    LEFT JOIN 
        PostComments PC ON TP.PostId = PC.PostId
)
SELECT 
    PostId,
    Title,
    CreationDate,
    Score,
    ViewCount,
    OwnerReputation,
    UpVotes,
    DownVotes,
    CommentCount,
    CASE 
        WHEN Score > 100 THEN 'Highly Engaging'
        WHEN Score BETWEEN 50 AND 100 THEN 'Moderately Engaging'
        ELSE 'Less Engaging'
    END AS EngagementLevel
FROM 
    FinalResult
ORDER BY 
    Score DESC, 
    ViewCount DESC
LIMIT 50;
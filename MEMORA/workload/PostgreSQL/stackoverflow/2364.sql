
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS Rank,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) OVER (PARTITION BY P.Id) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) OVER (PARTITION BY P.Id) AS DownVotes,
        P.OwnerUserId
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.PostTypeId = 1 AND 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        R.*,
        U.DisplayName AS OwnerDisplayName,
        U.Reputation
    FROM 
        RankedPosts R
    JOIN 
        Users U ON R.OwnerUserId = U.Id
    WHERE 
        R.Rank <= 5
),
PostDetails AS (
    SELECT 
        TP.PostId,
        TP.Title,
        TP.OwnerDisplayName,
        TP.Reputation,
        TP.Score,
        TP.ViewCount,
        COALESCE(TC.CommentCount, 0) AS TotalComments,
        COALESCE(TH.Upvotes, 0) - COALESCE(TH.Downvotes, 0) AS NetVotes
    FROM 
        TopPosts TP
    LEFT JOIN 
        (SELECT 
            PostId, 
            COUNT(*) AS CommentCount 
         FROM 
            Comments 
         GROUP BY 
            PostId) TC ON TP.PostId = TC.PostId
    LEFT JOIN 
        (SELECT 
            PostId, 
            COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS Upvotes,
            COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS Downvotes
         FROM 
            Votes 
         GROUP BY 
            PostId) TH ON TP.PostId = TH.PostId
)
SELECT 
    PD.Title,
    PD.OwnerDisplayName,
    PD.Reputation,
    PD.Score,
    PD.ViewCount,
    PD.TotalComments,
    PD.NetVotes
FROM 
    PostDetails PD
ORDER BY 
    PD.Reputation DESC, 
    PD.Score DESC
LIMIT 10;

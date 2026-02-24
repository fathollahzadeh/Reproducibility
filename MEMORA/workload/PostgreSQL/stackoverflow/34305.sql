
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerName,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS Rank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
RecentVotes AS (
    SELECT 
        V.PostId,
        COUNT(V.Id) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes V
    WHERE 
        V.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        V.PostId
),
TopPosts AS (
    SELECT
        RP.PostId,
        RP.Title,
        RP.ViewCount,
        RP.OwnerName,
        COALESCE(RV.VoteCount, 0) AS TotalVotes,
        COALESCE(RV.UpVotes, 0) AS Upvotes,
        COALESCE(RV.DownVotes, 0) AS Downvotes
    FROM
        RankedPosts RP
    LEFT JOIN 
        RecentVotes RV ON RP.PostId = RV.PostId
    WHERE 
        RP.Rank <= 5
)
SELECT 
    TP.PostId,
    TP.Title,
    TP.ViewCount,
    TP.OwnerName,
    TP.TotalVotes,
    TP.Upvotes,
    TP.Downvotes,
    (TP.Upvotes - TP.Downvotes) AS NetVotes
FROM 
    TopPosts TP
ORDER BY 
    NetVotes DESC;

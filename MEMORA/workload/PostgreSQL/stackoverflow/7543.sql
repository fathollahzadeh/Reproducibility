WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC, P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        OwnerDisplayName
    FROM  
        RankedPosts
    WHERE 
        PostRank <= 10
),
PostVoteSummary AS (
    SELECT 
        P.Id AS PostId,
        COUNT(V.Id) FILTER (WHERE V.VoteTypeId = 2) AS UpVotes,
        COUNT(V.Id) FILTER (WHERE V.VoteTypeId = 3) AS DownVotes,
        COUNT(V.Id) AS TotalVotes
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id
)
SELECT 
    T PostId,
    T.Title,
    T.CreationDate,
    T.Score,
    T.ViewCount,
    T.OwnerDisplayName,
    PVS.UpVotes,
    PVS.DownVotes,
    PVS.TotalVotes
FROM 
    TopPosts T
JOIN 
    PostVoteSummary PVS ON T.PostId = PVS.PostId
ORDER BY 
    T.Score DESC, T.CreationDate DESC;
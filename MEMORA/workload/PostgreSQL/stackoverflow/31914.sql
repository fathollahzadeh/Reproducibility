WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS PostRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopRatedPosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.Score,
        RP.CreationDate,
        RP.OwnerDisplayName
    FROM 
        RankedPosts RP
    WHERE 
        RP.PostRank <= 5
),
PostVoteCounts AS (
    SELECT 
        V.PostId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(V.Id) AS TotalVotes
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
),
PostHistoryActions AS (
    SELECT 
        PH.PostId,
        COUNT(PH.Id) AS EditCount
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        PH.PostId
)
SELECT 
    T.Title,
    T.Score,
    T.CreationDate,
    T.OwnerDisplayName,
    COALESCE(PV.UpVotes, 0) AS UpVotes,
    COALESCE(PV.DownVotes, 0) AS DownVotes,
    COALESCE(PC.CommentCount, 0) AS CommentCount,
    COALESCE(PH.EditCount, 0) AS EditCount
FROM 
    TopRatedPosts T
LEFT JOIN 
    PostVoteCounts PV ON T.PostId = PV.PostId
LEFT JOIN 
    PostComments PC ON T.PostId = PC.PostId
LEFT JOIN 
    PostHistoryActions PH ON T.PostId = PH.PostId
WHERE 
    T.Score > 0
ORDER BY 
    T.Score DESC, T.CreationDate DESC;
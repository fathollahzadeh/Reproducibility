WITH Benchmark AS (
    SELECT 
        P.Id AS PostId,
        P.CreationDate AS PostCreationDate,
        U.Reputation AS UserReputation,
        COUNT(C.Id) AS CommentCount,
        COUNT(V.Id) AS VoteCount,
        MAX(PH.CreationDate) AS LastHistoryActionDate
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        P.Id, P.CreationDate, U.Reputation
)
SELECT 
    PostId, 
    PostCreationDate, 
    UserReputation, 
    CommentCount, 
    VoteCount, 
    LastHistoryActionDate,
    EXTRACT(EPOCH FROM (cast('2024-10-01 12:34:56' as timestamp) - PostCreationDate)) AS AgeInSeconds,
    EXTRACT(EPOCH FROM (cast('2024-10-01 12:34:56' as timestamp) - LastHistoryActionDate)) AS LastActionLagInSeconds
FROM 
    Benchmark
ORDER BY 
    VoteCount DESC, 
    CommentCount DESC;
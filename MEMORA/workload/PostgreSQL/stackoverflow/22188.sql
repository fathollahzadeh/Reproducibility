
WITH UserVotes AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(V.Id) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        RANK() OVER (ORDER BY COUNT(V.Id) DESC) AS VoteRank
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PopularPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COUNT(C.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS OwnerPostRank
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.PostTypeId = 1
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount, P.OwnerUserId
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        PH.Comment AS CloseReason,
        COUNT(P.Id) AS RelatedCount
    FROM 
        PostHistory PH 
    JOIN 
        Posts P ON PH.PostId = P.Id
    WHERE 
        PH.PostHistoryTypeId = 10 
    GROUP BY 
        PH.PostId, PH.Comment
)

SELECT 
    U.DisplayName AS UserName,
    U.VoteCount,
    U.UpVotes,
    U.DownVotes,
    PP.PostId,
    PP.Title,
    PP.CreationDate,
    PP.Score,
    PP.ViewCount,
    COALESCE(CP.CloseReason, 'Not Closed') AS CloseReason,
    COALESCE(CP.RelatedCount, 0) AS RelatedCount
FROM 
    UserVotes U
JOIN 
    PopularPosts PP ON U.UserId = PP.OwnerPostRank   
LEFT JOIN 
    ClosedPosts CP ON PP.PostId = CP.PostId
WHERE 
    U.VoteRank <= 10  
    AND (U.UpVotes - U.DownVotes) > 5  
ORDER BY 
    U.VoteCount DESC, PP.Score DESC;

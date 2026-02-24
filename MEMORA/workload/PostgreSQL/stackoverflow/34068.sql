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
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS PostRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1 AND P.Score > 0
), 
RecentActivity AS (
    SELECT 
        P.Id AS PostId,
        COUNT(CASE WHEN C.UserId IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(V.Id) AS VoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId AND C.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    WHERE 
        P.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        P.Id
), 
PostHistoryData AS (
    SELECT 
        PH.PostId,
        COUNT(PH.Id) AS EditCount,
        MAX(PH.CreationDate) AS LastEditDate
    FROM 
        PostHistory PH
    JOIN 
        Posts P ON PH.PostId = P.Id
    WHERE 
        PH.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        PH.PostId
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    RP.Score,
    RP.ViewCount,
    RP.AnswerCount,
    RA.CommentCount AS RecentCommentCount,
    RA.VoteCount AS RecentVoteCount,
    COALESCE(PHD.EditCount, 0) AS EditCount,
    PHD.LastEditDate,
    RP.OwnerDisplayName
FROM 
    RankedPosts RP
LEFT JOIN 
    RecentActivity RA ON RP.PostId = RA.PostId
LEFT JOIN 
    PostHistoryData PHD ON RP.PostId = PHD.PostId
WHERE 
    RP.PostRank <= 5 
ORDER BY 
    RP.Score DESC, RP.ViewCount DESC;
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.AnswerCount,
        P.ViewCount,
        U.DisplayName AS Author,
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS PostRank,
        (SELECT COUNT(*) 
         FROM Votes V 
         WHERE V.PostId = P.Id AND V.VoteTypeId = 2) AS UpVoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        Score, 
        UpVoteCount, 
        ViewCount
    FROM 
        RankedPosts
    WHERE 
        PostRank <= 10
),
PostHistories AS (
    SELECT 
        PH.PostId,
        COUNT(*) AS EditCount,
        MAX(PH.CreationDate) AS LastEditDate,
        STRING_AGG(PHT.Name, ', ') AS EditTypes
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    GROUP BY 
        PH.PostId
)
SELECT 
    TP.Title,
    TP.Score,
    TP.UpVoteCount,
    TP.ViewCount,
    COALESCE(PH.EditCount, 0) AS TotalEdits,
    PH.LastEditDate,
    PH.EditTypes
FROM 
    TopPosts TP
LEFT JOIN 
    PostHistories PH ON TP.PostId = PH.PostId
ORDER BY 
    TP.Score DESC, TP.ViewCount DESC;
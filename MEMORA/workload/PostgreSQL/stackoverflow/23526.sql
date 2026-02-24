WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.CreationDate,
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC, P.ViewCount DESC) AS RankScore,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotesCount,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotesCount,
        COALESCE(P.ClosedDate, '9999-12-31') AS EffectiveCloseDate
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        P.Id, P.Title, P.Score, P.ViewCount, P.CreationDate, P.ClosedDate
),
PostComments AS (
    SELECT 
        C.PostId,
        COUNT(C.Id) AS CommentCount,
        STRING_AGG(C.Text, ' | ') AS CommentTexts
    FROM 
        Comments C
    GROUP BY 
        C.PostId
),
PostHistories AS (
    SELECT 
        PH.PostId,
        PH.UserId AS EditorUserId,
        PH.CreationDate AS EditDate,
        PHT.Name AS ChangeType,
        COUNT(*) AS EditCount
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    WHERE 
        PHT.Id IN (4, 5, 6) 
    GROUP BY 
        PH.PostId, PH.UserId, PH.CreationDate, PHT.Name
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.Score,
    RP.ViewCount,
    RP.RankScore,
    COALESCE(PC.CommentCount, 0) AS TotalComments,
    COALESCE(PC.CommentTexts, 'No comments') AS CommentTexts,
    COALESCE(PH.EditCount, 0) AS TotalEdits,
    CASE 
        WHEN RP.EffectiveCloseDate < cast('2024-10-01 12:34:56' as timestamp) THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus,
    CASE 
        WHEN RP.UpVotesCount > RP.DownVotesCount THEN CONCAT(RP.UpVotesCount, ' Upvotes')
        WHEN RP.UpVotesCount < RP.DownVotesCount THEN CONCAT(RP.DownVotesCount, ' Downvotes')
        ELSE 'Equal Votes'
    END AS VoteSummary
FROM 
    RankedPosts RP
LEFT JOIN 
    PostComments PC ON RP.PostId = PC.PostId
LEFT JOIN 
    PostHistories PH ON RP.PostId = PH.PostId
WHERE 
    RP.RankScore <= 10 
ORDER BY 
    RP.RankScore, RP.Score DESC;
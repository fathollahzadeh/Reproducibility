
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        U.DisplayName AS Author,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.CreationDate DESC) AS Rank,
        COALESCE(P.AcceptedAnswerId, -1) AS AcceptedStatus
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
PostScoreDetails AS (
    SELECT 
        RP.*,
        CASE 
            WHEN RP.Score > 0 THEN 'Positive'
            WHEN RP.Score < 0 THEN 'Negative'
            ELSE 'Neutral'
        END AS ScoreCategory
    FROM 
        RankedPosts RP
),
PopulatedTags AS (
    SELECT 
        P.Id AS PostId,
        STRING_AGG(T.TagName, ', ') AS TagsList
    FROM 
        Posts P
    LEFT JOIN 
        UNNEST(STRING_TO_ARRAY(P.Tags, '<>')) AS T(TagName) ON P.Id = P.Id
    GROUP BY 
        P.Id
),
PostHistorySummary AS (
    SELECT 
        PH.PostId,
        COUNT(CASE WHEN PH.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseReopenCount,
        MAX(PH.CreationDate) AS LastHistoryDate
    FROM 
        PostHistory PH
    GROUP BY 
        PH.PostId
)

SELECT 
    PSD.PostId,
    PSD.Title,
    PSD.Author,
    PSD.CreationDate,
    PSD.Score,
    PSD.ViewCount,
    PSD.ScoreCategory,
    PT.TagsList,
    COALESCE(PHS.CloseReopenCount, 0) AS CloseReopenStatus,
    PHS.LastHistoryDate,
    (SELECT COUNT(*) FROM Comments C WHERE C.PostId = PSD.PostId) AS CommentCount,
    (SELECT COUNT(*) FROM Votes V WHERE V.PostId = PSD.PostId AND V.VoteTypeId = 2) AS UpvoteCount,
    (SELECT COUNT(*) FROM Votes V WHERE V.PostId = PSD.PostId AND V.VoteTypeId = 3) AS DownvoteCount
FROM 
    PostScoreDetails PSD
LEFT JOIN 
    PopulatedTags PT ON PSD.PostId = PT.PostId
LEFT JOIN 
    PostHistorySummary PHS ON PSD.PostId = PHS.PostId
WHERE 
    PSD.Rank <= 5 
AND 
    PSD.AcceptedStatus IN (-1, (SELECT MAX(AcceptedAnswerId) FROM Posts WHERE ParentId = PSD.PostId))
ORDER BY 
    PSD.Score DESC, 
    PSD.ViewCount DESC, 
    PSD.CreationDate DESC;

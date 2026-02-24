
WITH RecentPostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.Score,
        COALESCE(P.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVoteCount,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        P.Id, P.Title, P.ViewCount, P.Score, P.AcceptedAnswerId
),
PostHistorySummary AS (
    SELECT 
        PH.PostId,
        COUNT(PH.Id) AS EditCount,
        MAX(PH.CreationDate) AS LastEditDate,
        STRING_AGG(PH.Comment, '; ') AS EditComments
    FROM 
        PostHistory PH
    GROUP BY 
        PH.PostId
),
PostDetails AS (
    SELECT 
        RPS.PostId,
        RPS.Title,
        RPS.ViewCount,
        RPS.Score,
        RPS.AcceptedAnswerId,
        RPS.UpVoteCount,
        RPS.DownVoteCount,
        PHS.EditCount,
        PHS.LastEditDate,
        PHS.EditComments,
        CASE 
            WHEN RPS.Score = 0 THEN 'No Score'
            WHEN RPS.Score > 0 THEN 'Positive Score'
            ELSE 'Negative Score'
        END AS ScoreCategory,
        CASE 
            WHEN RPS.AcceptedAnswerId = -1 THEN 'No Accepted Answer'
            ELSE 'Has Accepted Answer'
        END AS AnswerStatus
    FROM 
        RecentPostStats RPS
    LEFT JOIN 
        PostHistorySummary PHS ON RPS.PostId = PHS.PostId
)
SELECT 
    PD.PostId,
    PD.Title,
    PD.ViewCount,
    PD.Score,
    PD.UpVoteCount,
    PD.DownVoteCount,
    PD.EditCount,
    PD.LastEditDate,
    PD.EditComments,
    PD.ScoreCategory,
    PD.AnswerStatus,
    CASE 
        WHEN PD.ViewCount IS NULL THEN 'Unobserved Views' 
        ELSE 'Observed Views'
    END AS ViewObservation,
    ARRAY_LENGTH(STRING_TO_ARRAY(PD.EditComments, '; '), 1) AS NumberOfDistinctComments,
    (
        SELECT COUNT(*)
        FROM Comments C 
        WHERE C.PostId = PD.PostId
        AND C.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '14 days'
    ) AS RecentCommentCount
FROM 
    PostDetails PD
WHERE 
    PD.EditCount > 0 
    AND PD.ScoreCategory = 'Positive Score'
ORDER BY 
    PD.ViewCount DESC, PD.Score DESC
LIMIT 10;

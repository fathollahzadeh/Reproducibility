
WITH PostStatistics AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.CreationDate,
        P.PostTypeId,
        COALESCE(P.AnswerCount, 0) AS AnswerCount,
        COALESCE(P.CommentCount, 0) AS CommentCount,
        U.Reputation,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.ViewCount DESC) AS Rank,
        RANK() OVER (ORDER BY P.Score DESC) AS ScoreRank
    FROM
        Posts P
    JOIN
        Users U ON P.OwnerUserId = U.Id
    WHERE
        P.CreationDate > (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
),
RecentVotes AS (
    SELECT
        V.PostId,
        V.VoteTypeId,
        COUNT(*) AS VoteCount
    FROM
        Votes V
    WHERE
        V.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 month')
    GROUP BY
        V.PostId, V.VoteTypeId
),
ClosedPosts AS (
    SELECT
        PH.PostId,
        MAX(PH.CreationDate) AS LastClosedDate,
        STRING_AGG(DISTINCT CR.Name, ', ') AS CloseReasons
    FROM
        PostHistory PH
    JOIN
        CloseReasonTypes CR ON PH.Comment::INTEGER = CR.Id
    WHERE
        PH.PostHistoryTypeId IN (10, 11) 
    GROUP BY
        PH.PostId
)
SELECT
    PS.PostId,
    PS.Title,
    PS.ViewCount,
    PS.AnswerCount,
    PS.CommentCount,
    PS.Reputation,
    RV.VoteCount,
    CP.LastClosedDate,
    CP.CloseReasons,
    PS.Rank,
    PS.ScoreRank,
    CASE
        WHEN PS.AnswerCount > 0 THEN 'Active'
        WHEN CP.LastClosedDate IS NOT NULL AND PS.ScoreRank <= 10 THEN 'Needs Attention'
        ELSE 'Backlog'
    END AS PostStatus,
    CASE
        WHEN PS.PostTypeId = 1 THEN 'Question'
        WHEN PS.PostTypeId = 2 THEN 'Answer'
        ELSE 'Other'
    END AS PostType
FROM
    PostStatistics PS
LEFT JOIN
    RecentVotes RV ON PS.PostId = RV.PostId AND RV.VoteTypeId IN (2, 3) 
LEFT JOIN
    ClosedPosts CP ON PS.PostId = CP.PostId
WHERE
    PS.Rank <= 10 
ORDER BY
    PS.ViewCount DESC, PS.Reputation DESC;

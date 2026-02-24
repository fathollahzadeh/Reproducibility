
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.CreationDate,
        P.AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC, P.CreationDate ASC) AS Rank
    FROM Posts P
    WHERE P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
UserVotes AS (
    SELECT 
        V.PostId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM Votes V
    GROUP BY V.PostId
),
OpenQuestions AS (
    SELECT 
        PQ.Id AS QuestionId,
        PQ.Title,
        PQ.AcceptedAnswerId,
        COUNT(A.Id) AS AnswerCount,
        COALESCE(PH.Comment, 'No close reason') AS CloseReason
    FROM Posts PQ
    LEFT JOIN Posts A ON A.ParentId = PQ.Id
    LEFT JOIN PostHistory PH ON PQ.Id = PH.PostId AND PH.PostHistoryTypeId = 10
    WHERE PQ.PostTypeId = 1 AND PQ.ClosedDate IS NULL
    GROUP BY PQ.Id, PH.Comment
),
PostDetails AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.Score,
        RP.ViewCount,
        UV.Upvotes,
        UV.Downvotes,
        OQ.CloseReason
    FROM RankedPosts RP
    LEFT JOIN UserVotes UV ON RP.PostId = UV.PostId
    LEFT JOIN OpenQuestions OQ ON RP.PostId = OQ.QuestionId
    WHERE RP.Rank <= 5 
)
SELECT 
    PD.Title,
    PD.Score,
    PD.ViewCount,
    COALESCE(PD.Upvotes, 0) AS Upvotes,
    COALESCE(PD.Downvotes, 0) AS Downvotes,
    CASE 
        WHEN PD.CloseReason IS NOT NULL 
             THEN CONCAT('Closed: ', PD.CloseReason) 
        ELSE 'Open' 
    END AS Status
FROM PostDetails PD
ORDER BY PD.Score DESC, PD.ViewCount DESC;

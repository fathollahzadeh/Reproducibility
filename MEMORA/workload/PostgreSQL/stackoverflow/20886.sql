
WITH PostVoteCounts AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM Votes
    GROUP BY PostId
),
AcceptedAnswers AS (
    SELECT 
        p.Id AS QuestionId,
        p.AcceptedAnswerId,
        pa.Score AS AcceptedAnswerScore,
        COALESCE(u.DisplayName, 'Anonymous') AS AcceptedAnswerUser
    FROM Posts p
    LEFT JOIN Posts pa ON p.AcceptedAnswerId = pa.Id
    LEFT JOIN Users u ON pa.OwnerUserId = u.Id
    WHERE p.PostTypeId = 1
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes,
        MAX(ph.CreationDate) AS LastModifiedDate,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS TotalCloseVotes,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 END) AS TotalReopenVotes
    FROM PostHistory ph
    JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY ph.PostId
)
SELECT 
    p.Id AS PostId,
    p.Title,
    p.Body,
    pc.UpVotes,
    pc.DownVotes,
    ah.QuestionId,
    ah.AcceptedAnswerId,
    ah.AcceptedAnswerScore,
    ah.AcceptedAnswerUser,
    phd.HistoryTypes,
    phd.LastModifiedDate,
    CASE 
        WHEN phd.TotalCloseVotes > 0 THEN 'Closed'
        WHEN phd.TotalReopenVotes > 0 THEN 'Reopened'
        ELSE 'Active'
    END AS PostStatus
FROM Posts p
LEFT JOIN PostVoteCounts pc ON p.Id = pc.PostId
LEFT JOIN AcceptedAnswers ah ON p.Id = ah.QuestionId
LEFT JOIN PostHistoryDetails phd ON p.Id = phd.PostId
WHERE p.CreationDate > CURRENT_DATE - INTERVAL '1 year'
AND (p.ViewCount > 100 OR pc.TotalVotes > 10)
ORDER BY p.Score DESC, phd.LastModifiedDate DESC
LIMIT 50;

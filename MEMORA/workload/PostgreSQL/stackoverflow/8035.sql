WITH RankUserReputation AS (
    SELECT
        Id AS UserId,
        Reputation,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM
        Users
),
RecentPostStats AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Posts a WHERE a.ParentId = p.Id) AS AnswerCount,
        CASE 
            WHEN EXISTS (SELECT 1 FROM Posts WHERE Id = p.AcceptedAnswerId) THEN 1 
            ELSE 0 
        END AS HasAcceptedAnswer
    FROM
        Posts p
    JOIN
        Users u ON p.OwnerUserId = u.Id
    WHERE
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
),
PostHistorySummary AS (
    SELECT
        PostId,
        COUNT(CASE WHEN PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN PostHistoryTypeId = 11 THEN 1 END) AS ReopenCount,
        COUNT(CASE WHEN PostHistoryTypeId IN (12, 13) THEN 1 END) AS DeleteUndeleteCount,
        COUNT(*) AS TotalEdits
    FROM
        PostHistory
    GROUP BY
        PostId
)
SELECT
    p.PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    p.CommentCount,
    p.AnswerCount,
    p.HasAcceptedAnswer,
    ph.CloseCount,
    ph.ReopenCount,
    ph.DeleteUndeleteCount,
    ph.TotalEdits,
    r.UserId AS TopUserId,
    r.Reputation,
    r.ReputationRank
FROM
    RecentPostStats p
LEFT JOIN
    PostHistorySummary ph ON p.PostId = ph.PostId
JOIN
    RankUserReputation r ON p.OwnerUserId = r.UserId
ORDER BY
    p.CreationDate DESC, p.ViewCount DESC
LIMIT 100;
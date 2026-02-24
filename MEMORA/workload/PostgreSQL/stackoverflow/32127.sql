WITH RECURSIVE UserVotes AS (
    
    SELECT
        u.Id AS UserId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 
                 WHEN v.VoteTypeId = 3 THEN -1 
                 ELSE 0 END) AS TotalScore,
        COUNT(DISTINCT v.PostId) AS TotalVotes
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id
), 
PostAnalytics AS (
    
    SELECT
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS HasAcceptedAnswer,
        MAX(v.CreationDate) AS LastVoteDate
    FROM Posts p
    LEFT JOIN Posts a ON p.Id = a.ParentId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.PostTypeId = 1 
    GROUP BY p.Id, p.Title, p.ViewCount
), 
PostHistoryChanges AS (
    
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN ph.CreationDate END) AS LastClosedDate,
        MAX(CASE WHEN ph.PostHistoryTypeId IN (1, 4, 24) THEN ph.CreationDate END) AS LastEditedDate,
        COUNT(DISTINCT ph.Id) AS TotalHistoryRecords
    FROM PostHistory ph
    GROUP BY ph.PostId
)
SELECT 
    u.DisplayName AS UserName,
    u.Reputation,
    ua.TotalScore,
    p.Title,
    p.ViewCount,
    p.AnswerCount,
    ph.LastClosedDate,
    ph.LastEditedDate,
    ph.TotalHistoryRecords,
    CASE 
        WHEN p.HasAcceptedAnswer > 0 THEN 'YES' 
        ELSE 'NO' 
    END AS AcceptedAnswer,
    CASE 
        WHEN ph.LastClosedDate IS NOT NULL 
             AND ph.LastClosedDate >= p.LastVoteDate THEN 'Closed Recently' 
        ELSE 'Active'
    END AS PostStatus
FROM Users u
JOIN UserVotes ua ON u.Id = ua.UserId
JOIN PostAnalytics p ON u.Id IN (SELECT OwnerUserId FROM Posts WHERE PostTypeId = 1)
JOIN PostHistoryChanges ph ON p.PostId = ph.PostId
WHERE ua.TotalVotes > 5 
ORDER BY ua.TotalScore DESC, p.ViewCount DESC;
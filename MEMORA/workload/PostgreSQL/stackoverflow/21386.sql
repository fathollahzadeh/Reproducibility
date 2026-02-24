
WITH RecursiveCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        COALESCE(ah.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        COUNT(DISTINCT c.Id) AS CommentCount, 
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Posts ah ON p.AcceptedAnswerId = ah.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, u.DisplayName, ah.AcceptedAnswerId, p.CreationDate, p.Score
), 

PostHistoryData AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
),

FinalData AS (
    SELECT 
        r.PostId,
        r.Title,
        r.CreationDate,
        r.OwnerDisplayName,
        r.Score,
        r.CommentCount,
        r.AcceptedAnswerId,
        r.UpVotes,
        r.DownVotes,
        phd.HistoryTypes,
        phd.LastEditDate
    FROM 
        RecursiveCTE r
    LEFT JOIN PostHistoryData phd ON r.PostId = phd.PostId
)

SELECT 
    fd.PostId,
    fd.Title,
    fd.CreationDate,
    fd.OwnerDisplayName,
    COALESCE(fd.CommentCount, 0) AS TotalComments,
    fd.Score AS PostScore,
    CASE 
        WHEN fd.AcceptedAnswerId = 0 THEN 'No accepted answer'
        ELSE (SELECT Title FROM Posts WHERE Id = fd.AcceptedAnswerId)
    END AS AcceptedAnswerTitle,
    fd.UpVotes - fd.DownVotes AS NetVotes,
    fd.HistoryTypes,
    fd.LastEditDate,
    CASE 
        WHEN (SELECT COUNT(*) FROM Comments WHERE PostId = fd.PostId) = 0 THEN 'No comments yet'
        ELSE 'Comments available'
    END AS CommentStatus
FROM FinalData fd
ORDER BY fd.CreationDate DESC
LIMIT 100;

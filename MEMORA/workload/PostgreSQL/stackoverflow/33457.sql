WITH RecursiveCTE AS (
    
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 'Accepted Answer' ELSE 'Unanswered' END AS AnswerStatus
    FROM 
        Posts p 
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
),
RecentActivity AS (
    
    SELECT 
        u.Id AS UserId,
        MAX(v.CreationDate) AS LastVoteDate,
        COUNT(DISTINCT v.Id) AS TotalVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
PostHistoryWithVotes AS (
    
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.PostHistoryTypeId,
        COUNT(v.Id) AS VoteCount
    FROM 
        PostHistory ph
    LEFT JOIN 
        Votes v ON ph.PostId = v.PostId
    GROUP BY 
        ph.PostId, ph.UserId, ph.PostHistoryTypeId
)
SELECT 
    r.PostId,
    r.Title,
    r.CreationDate,
    r.Score,
    r.ViewCount,
    r.AnswerCount,
    r.AnswerStatus,
    COALESCE(a.Reputation, 0) AS OwnerReputation,
    ra.LastVoteDate,
    ra.TotalVotes,
    COUNT(pv.VoteCount) FILTER (WHERE pv.PostHistoryTypeId IN (10, 11)) AS CloseVotes,
    SUM(CASE 
        WHEN pv.PostHistoryTypeId = 10 THEN 1 
        ELSE 0 
    END) AS TotalClosureActions,
    STRING_AGG(DISTINCT CASE WHEN pv.PostHistoryTypeId = 10 THEN 'Closed' ELSE NULL END, ', ') AS ClosureRemarks
FROM 
    RecursiveCTE r
LEFT JOIN 
    Users a ON r.OwnerUserId = a.Id
LEFT JOIN 
    RecentActivity ra ON r.OwnerUserId = ra.UserId
LEFT JOIN 
    PostHistoryWithVotes pv ON r.PostId = pv.PostId
GROUP BY 
    r.PostId, r.Title, r.CreationDate, r.Score, r.ViewCount, r.AnswerCount, r.AnswerStatus, a.Reputation, ra.LastVoteDate, ra.TotalVotes
ORDER BY 
    r.Score DESC, r.CreationDate DESC
LIMIT 100;
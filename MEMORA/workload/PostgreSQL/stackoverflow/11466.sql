WITH PostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.LastActivityDate,
        p.AnswerCount,
        p.CommentCount,
        p.ViewCount,
        u.Reputation AS OwnerReputation,
        COUNT(c.Id) AS TotalComments,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= '2022-01-01' 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.LastActivityDate, p.AnswerCount, p.CommentCount, p.ViewCount, u.Reputation
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS ChangeCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
)
SELECT 
    pa.PostId,
    pa.Title,
    pa.CreationDate,
    pa.LastActivityDate,
    pa.AnswerCount,
    pa.CommentCount,
    pa.ViewCount,
    pa.OwnerReputation,
    phs.ChangeCount AS TotalPostChanges,
    phs2.ChangeCount AS TotalCloseVotes
FROM 
    PostActivity pa
LEFT JOIN 
    PostHistorySummary phs ON pa.PostId = phs.PostId AND phs.PostHistoryTypeId IN (10, 11) 
LEFT JOIN 
    PostHistorySummary phs2 ON pa.PostId = phs2.PostId AND phs2.PostHistoryTypeId = 12 
ORDER BY 
    pa.ViewCount DESC;
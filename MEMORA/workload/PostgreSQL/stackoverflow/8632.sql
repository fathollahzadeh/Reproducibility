WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        COUNT(c.Id) AS TotalComments,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes,
        AVG(u.Reputation) AS AvgUserReputation
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.PostTypeId
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS TotalCloseVotes,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (11, 13) THEN 1 END) AS TotalOpenVotes
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.PostTypeId,
    ps.TotalComments,
    ps.UpVotes,
    ps.DownVotes,
    ps.AvgUserReputation,
    phs.TotalCloseVotes,
    phs.TotalOpenVotes
FROM 
    PostStats ps
LEFT JOIN 
    PostHistorySummary phs ON ps.PostId = phs.PostId
ORDER BY 
    ps.UpVotes - ps.DownVotes DESC,
    ps.TotalComments DESC;

WITH RecursivePostStats AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.PostTypeId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 YEAR'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.PostTypeId
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS ChangeCount
    FROM 
        PostHistory ph 
    WHERE 
        ph.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '6 MONTH'
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
),
RankedPosts AS (
    SELECT 
        r.Id,
        r.Title,
        r.CommentCount,
        r.UpVotes - r.DownVotes AS NetVotes,
        ROW_NUMBER() OVER (PARTITION BY r.PostTypeId ORDER BY r.CommentCount DESC, r.CreationDate ASC) AS Rank
    FROM 
        RecursivePostStats r
    WHERE 
        r.CommentCount > 0
)
SELECT 
    p.Id,
    p.Title,
    ps.CommentCount,
    ps.UpVotes,
    ps.DownVotes,
    phs.ChangeCount AS HistoryChangeCount,
    CASE 
        WHEN p.PostTypeId = 1 THEN 'Question'
        ELSE 'Answer'
    END AS PostType,
    COALESCE(rp.Rank, 0) AS PostRank
FROM 
    Posts p
JOIN 
    RecursivePostStats ps ON p.Id = ps.Id
LEFT JOIN 
    PostHistorySummary phs ON p.Id = phs.PostId
LEFT JOIN 
    RankedPosts rp ON p.Id = rp.Id
WHERE 
    ps.CommentCount > 5
    AND ((ps.UpVotes - ps.DownVotes) > 0 OR (phs.ChangeCount IS NOT NULL AND phs.ChangeCount > 2))
ORDER BY 
    ps.UpVotes DESC, ps.CommentCount DESC, phs.ChangeCount DESC;


WITH PostVoteSummary AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotesCount,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotesCount,
        COUNT(v.Id) AS TotalVotesCount,
        MAX(v.CreationDate) AS LastVoteDate
    FROM 
        Posts p
        LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '6 months'
    GROUP BY 
        p.Id, p.PostTypeId
),
ClosedPostHistory AS (
    SELECT 
        ph.PostId, 
        ph.CreationDate,
        ph.UserDisplayName,
        COALESCE(NULLIF(pr.Name, ''), 'Unknown Reason') AS CloseReason
    FROM 
        PostHistory ph
        JOIN CloseReasonTypes pr ON CAST(ph.Comment AS INT) = pr.Id
    WHERE 
        ph.PostHistoryTypeId = 10
),
TopPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        ps.UpVotesCount - ps.DownVotesCount AS NetVotes,
        ROW_NUMBER() OVER (ORDER BY p.CreationDate DESC, ps.UpVotesCount - ps.DownVotesCount DESC) AS Rank
    FROM 
        Posts p
        JOIN PostVoteSummary ps ON p.Id = ps.PostId
    WHERE 
        ps.TotalVotesCount > 5 
)

SELECT 
    tp.Title,
    tp.ViewCount,
    tp.CreationDate,
    tp.NetVotes,
    ph.CreationDate AS CloseDate,
    ph.UserDisplayName AS ClosedBy,
    ph.CloseReason
FROM 
    TopPosts tp
    LEFT JOIN ClosedPostHistory ph ON tp.Id = ph.PostId
WHERE 
    tp.Rank <= 10
ORDER BY 
    tp.NetVotes DESC, tp.CreationDate DESC;

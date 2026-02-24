
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(v.UpVotes, 0) AS TotalUpVotes,
        COALESCE(v.DownVotes, 0) AS TotalDownVotes,
        COUNT(c.Id) AS CommentCount,
        COUNT(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 END) AS HasAcceptedAnswer,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM 
            Votes
        GROUP BY 
            PostId) v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, v.UpVotes, v.DownVotes, p.OwnerUserId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount,
        MAX(ph.CreationDate) AS LastClosedDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
),
FinalStats AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.CreationDate,
        ps.TotalUpVotes,
        ps.TotalDownVotes,
        ps.CommentCount,
        ps.HasAcceptedAnswer,
        cp.CloseCount,
        cp.LastClosedDate
    FROM 
        PostStats ps
    LEFT JOIN 
        ClosedPosts cp ON ps.PostId = cp.PostId
)
SELECT 
    fs.PostId,
    fs.Title,
    fs.CreationDate,
    fs.TotalUpVotes,
    fs.TotalDownVotes,
    fs.CommentCount,
    fs.HasAcceptedAnswer,
    COALESCE(fs.CloseCount, 0) AS CloseCount,
    COALESCE(fs.LastClosedDate, '1900-01-01') AS LastClosedDate
FROM 
    FinalStats fs
WHERE 
    fs.TotalUpVotes - fs.TotalDownVotes > 10 
    OR fs.CommentCount > 5
ORDER BY 
    fs.CreationDate DESC
OFFSET 20 ROWS FETCH NEXT 10 ROWS ONLY;

WITH RecursivePostHistory AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserId,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS RevisionRank
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON p.Id = ph.PostId
    WHERE 
        ph.CreationDate < cast('2024-10-01 12:34:56' as timestamp) 
),
AggregatedVotes AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.PostId
),
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        ph.CreationDate AS ClosedDate,
        u.DisplayName AS ModeratorName
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON ph.PostId = p.Id AND ph.PostHistoryTypeId IN (10, 11) 
    JOIN 
        Users u ON ph.UserId = u.Id
    WHERE 
        ph.PostHistoryTypeId = 10 
),
RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        COALESCE(av.UpVotes, 0) AS TotalUpVotes,
        COALESCE(av.DownVotes, 0) AS TotalDownVotes,
        COALESCE(cp.ClosedDate, '1970-01-01') AS ClosedDate,
        ROW_NUMBER() OVER (ORDER BY p.ViewCount DESC, p.CreationDate ASC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        AggregatedVotes av ON p.Id = av.PostId
    LEFT JOIN 
        ClosedPosts cp ON p.Id = cp.PostId
)
SELECT 
    rp.Id AS PostId,
    rp.Title,
    rp.ViewCount,
    rp.TotalUpVotes,
    rp.TotalDownVotes,
    rp.ClosedDate,
    CASE 
        WHEN rp.ClosedDate > '1970-01-01' THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus,
    CASE 
        WHEN rp.Rank <= 10 THEN 'Top 10'
        ELSE 'Other'
    END AS RankGroup
FROM 
    RankedPosts rp
WHERE 
    rp.TotalDownVotes < rp.TotalUpVotes 
    AND rp.Rank <= 20 
ORDER BY 
    rp.Rank, rp.ViewCount DESC;
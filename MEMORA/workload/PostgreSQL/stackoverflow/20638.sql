WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts AS p
    WHERE 
        p.CreationDate >= (cast('2024-10-01' as date) - INTERVAL '1 year')
),

PostVotes AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN vt.Id = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Id = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON vt.Id = v.VoteTypeId
    GROUP BY 
        v.PostId
),

PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN pht.Name = 'Post Closed' THEN ph.CreationDate END) AS LastClosedDate,
        MAX(CASE WHEN pht.Name = 'Post Reopened' THEN ph.CreationDate END) AS LastReopenedDate
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
),

FinalPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.CreationDate,
        rp.Score,
        pv.UpVotes,
        pv.DownVotes,
        COALESCE(ph.LastClosedDate, '1970-01-01') AS LastClosedDate,
        COALESCE(ph.LastReopenedDate, '1970-01-01') AS LastReopenedDate
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostVotes pv ON rp.PostId = pv.PostId
    LEFT JOIN 
        PostHistoryDetails ph ON rp.PostId = ph.PostId
    WHERE 
        rp.Rank <= 10  
)

SELECT 
    fp.PostId,
    fp.Title,
    fp.ViewCount,
    fp.CreationDate,
    fp.Score,
    fp.UpVotes,
    fp.DownVotes,
    CASE 
        WHEN fp.LastClosedDate = '1970-01-01' THEN NULL 
        ELSE fp.LastClosedDate 
    END AS ClosedDate,
    CASE 
        WHEN fp.LastReopenedDate = '1970-01-01' THEN NULL 
        ELSE fp.LastReopenedDate 
    END AS ReopenedDate
FROM 
    FinalPosts fp
WHERE 
    fp.UpVotes > fp.DownVotes
ORDER BY 
    fp.ViewCount DESC, 
    fp.CreationDate DESC;
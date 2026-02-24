
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE(p.Score, 0) AS Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC, COALESCE(p.Score, 0) DESC) AS Rank,
        ARRAY_AGG(t.TagName) AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON t.WikiPostId = p.Id
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.PostTypeId
),
PostVoteStats AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
PostHistoryFiltered AS (
    SELECT 
        h.PostId,
        h.CreationDate,
        MAX(h.CreationDate) OVER (PARTITION BY h.PostId) AS MostRecentEditDate
    FROM 
        PostHistory h
    WHERE 
        h.PostHistoryTypeId IN (4, 5, 6) 
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    pvs.UpVotes,
    pvs.DownVotes,
    rp.Score,
    rp.Tags,
    CASE 
        WHEN pfs.MostRecentEditDate IS NULL THEN 'No Edits Found'
        WHEN pfs.MostRecentEditDate < rp.CreationDate THEN 'Edited Before Creation'
        ELSE 'Edited After Creation'
    END AS EditStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    PostVoteStats pvs ON rp.PostId = pvs.PostId
LEFT JOIN 
    PostHistoryFiltered pfs ON rp.PostId = pfs.PostId
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.ViewCount DESC 
LIMIT 10;

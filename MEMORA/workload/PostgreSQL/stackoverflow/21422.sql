
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate ASC) AS RN,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVoteCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownVoteCount
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 YEAR'
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.UpVoteCount,
    rp.DownVoteCount,
    COALESCE(pht.Name, 'Unknown') AS HistoryType,
    COALESCE(lt.Name, 'No Links') AS LinkType,
    SUM(CASE WHEN a.Answered = 1 THEN 1 ELSE 0 END) AS TotalAnswers,
    NULLIF(MAX(v.BountyAmount), 0) AS MaxBounty
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistory ph ON rp.PostId = ph.PostId 
LEFT JOIN 
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
LEFT JOIN 
    PostLinks pl ON rp.PostId = pl.PostId
LEFT JOIN 
    LinkTypes lt ON pl.LinkTypeId = lt.Id
LEFT JOIN 
    (SELECT 
        ParentId,
        COUNT(*) AS Answered
    FROM 
        Posts 
    WHERE 
        PostTypeId = 2 
    GROUP BY 
        ParentId) a ON rp.PostId = a.ParentId
LEFT JOIN 
    Votes v ON rp.PostId = v.PostId AND v.VoteTypeId = 8  
WHERE 
    rp.RN <= 5
GROUP BY 
    rp.PostId, rp.Title, rp.CreationDate, rp.Score, rp.ViewCount, 
    rp.UpVoteCount, rp.DownVoteCount, pht.Name, lt.Name
ORDER BY 
    TotalAnswers DESC, 
    rp.ViewCount DESC;


WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE(SUM(CASE WHEN vt.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN vt.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        US.DisplayName AS OwnerDisplayName,
        RANK() OVER (ORDER BY p.Score DESC) AS RankScore,
        RANK() OVER (ORDER BY p.ViewCount DESC) AS RankViews
    FROM 
        Posts p
    LEFT JOIN 
        Votes vt ON p.Id = vt.PostId
    LEFT JOIN 
        Users US ON p.OwnerUserId = US.Id
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, US.DisplayName
),
TopPosts AS (
    SELECT 
        rp.*, 
        RANK() OVER (PARTITION BY RankScore ORDER BY RankViews) AS RankByViews
    FROM 
        RankedPosts rp
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.UpVotes,
    tp.DownVotes,
    tp.OwnerDisplayName,
    tp.RankScore,
    tp.RankByViews
FROM 
    TopPosts tp
WHERE 
    tp.RankScore <= 10 
    AND tp.RankByViews <= 5 
ORDER BY 
    tp.RankScore, tp.RankByViews;

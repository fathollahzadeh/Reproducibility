
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.Tags, p.CreationDate, u.DisplayName, p.PostTypeId, p.Score
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.Tags,
    rp.CreationDate,
    rp.OwnerDisplayName,
    rp.CommentCount,
    rp.UpVoteCount,
    rp.DownVoteCount,
    CASE 
        WHEN rp.Rank <= 10 THEN 'Top 10'
        WHEN rp.Rank BETWEEN 11 AND 50 THEN 'Top 51-100'
        ELSE 'Others'
    END AS RankingCategory
FROM 
    RankedPosts rp
WHERE 
    rp.Rank <= 100
ORDER BY 
    RankingCategory, rp.ViewCount DESC;

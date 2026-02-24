
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, u.DisplayName
), RecentVotes AS (
    SELECT 
        v.PostId,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    WHERE 
        v.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '6 months'
    GROUP BY 
        v.PostId
), CombinedResults AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName,
        rp.CommentCount,
        COALESCE(rv.TotalVotes, 0) AS TotalVotes,
        COALESCE(rv.UpVotes, 0) AS UpVotes,
        COALESCE(rv.DownVotes, 0) AS DownVotes,
        rp.RankByScore
    FROM 
        RankedPosts rp
    LEFT JOIN 
        RecentVotes rv ON rp.Id = rv.PostId
)
SELECT 
    cr.*,
    CASE 
        WHEN cr.ViewCount > 1000 THEN 'Hot'
        WHEN cr.UpVotes > 100 THEN 'Popular'
        ELSE 'Regular'
    END AS PostCategory,
    CASE 
        WHEN cr.RankByScore = 1 THEN 'Top post in category'
        ELSE NULL
    END AS TopPostRemark
FROM 
    CombinedResults cr
WHERE 
    cr.RankByScore <= 10
ORDER BY 
    cr.Score DESC, cr.ViewCount DESC;

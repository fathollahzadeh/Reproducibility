WITH RankedPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.ViewCount, 
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS RankPerUser,
        COUNT(*) OVER (PARTITION BY p.OwnerUserId) AS TotalPostsByUser
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
),
RecentVotes AS (
    SELECT 
        v.PostId, 
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.PostId
),
PostAnalytics AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.ViewCount,
        rp.RankPerUser,
        rp.TotalPostsByUser,
        COALESCE(rv.TotalVotes, 0) AS TotalVotes,
        COALESCE(rv.UpVotes, 0) AS UpVotes,
        COALESCE(rv.DownVotes, 0) AS DownVotes,
        CASE 
            WHEN rp.RankPerUser = 1 THEN 'Most Viewed'
            WHEN rp.ViewCount > 100 THEN 'Popular'
            ELSE 'Regular'
        END AS PostCategory
    FROM 
        RankedPosts rp
    LEFT JOIN 
        RecentVotes rv ON rp.Id = rv.PostId
    WHERE 
        rp.TotalPostsByUser > 2
),
PostHistoryAnalysis AS (
    SELECT 
        ph.PostId, 
        COUNT(ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6)  
    GROUP BY 
        ph.PostId
)

SELECT 
    pa.Title,
    pa.ViewCount,
    pa.TotalVotes,
    pa.UpVotes,
    pa.DownVotes,
    pha.EditCount,
    pha.LastEditDate,
    pa.PostCategory,
    CASE 
        WHEN pa.PostCategory = 'Most Viewed' THEN 'Featured'
        WHEN pa.UpVotes > pa.DownVotes THEN 'Positive'
        ELSE 'Needs Attention'
    END AS PostStatus
FROM 
    PostAnalytics pa
LEFT JOIN 
    PostHistoryAnalysis pha ON pa.Id = pha.PostId
WHERE 
    (pa.UpVotes IS NOT NULL OR pa.DownVotes IS NOT NULL)
    AND pa.Title IS NOT NULL
    AND pa.ViewCount IS NOT NULL
ORDER BY 
    pa.ViewCount DESC
LIMIT 50;
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        DENSE_RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank,
        MAX(CASE 
            WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 
            ELSE 0 
        END) AS IsClosed
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        rp.*,
        CASE 
            WHEN rp.ViewCount IS NULL THEN 'No Views' 
            ELSE CASE 
                WHEN rp.ViewCount > 1000 THEN 'High Views' 
                WHEN rp.ViewCount BETWEEN 100 AND 1000 THEN 'Moderate Views' 
                ELSE 'Low Views' 
            END 
        END AS ViewCategory,
        CASE 
            WHEN rp.ScoreRank <= 10 THEN 'Top Posts' 
            ELSE 'Others' 
        END AS PostCategory
    FROM 
        RankedPosts rp
    WHERE 
        rp.CommentCount > 5 OR rp.Score > 0
),
AggregatedData AS (
    SELECT 
        fp.ViewCategory,
        fp.PostCategory,
        COUNT(fp.PostId) AS PostCount,
        AVG(fp.Score) AS AvgScore,
        SUM(CASE WHEN fp.IsClosed = 1 THEN 1 ELSE 0 END) AS ClosedCount
    FROM 
        FilteredPosts fp
    GROUP BY 
        fp.ViewCategory, fp.PostCategory
)
SELECT 
    ad.ViewCategory,
    ad.PostCategory,
    ad.PostCount,
    ad.AvgScore,
    ad.ClosedCount,
    COALESCE(
        (SELECT COUNT(*) FROM Posts p WHERE p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 month' AND p.Score IS NULL), 
        0
    ) AS NewZeroScorePosts
FROM 
    AggregatedData ad
ORDER BY 
    ad.ViewCategory, ad.PostCategory;
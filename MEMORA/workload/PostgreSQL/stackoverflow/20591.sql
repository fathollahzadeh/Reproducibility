WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.PostTypeId,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS Author,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
        AND p.ViewCount > (SELECT AVG(ViewCount) FROM Posts WHERE CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year')
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount,
        STRING_AGG(DISTINCT CONCAT_WS(' - ', ctr.Name, ph.CreationDate::TEXT), '; ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes ctr ON ph.Comment::int = ctr.Id 
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        ph.PostId
),
TopRankedPosts AS (
    SELECT 
        rp.PostID,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        rp.Author,
        cr.CloseCount,
        cr.CloseReasons
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ClosedPosts cr ON rp.PostID = cr.PostId
    WHERE 
        rp.Rank <= 5
        AND (cr.CloseCount IS NULL OR cr.CloseCount < 3) 
)
SELECT 
    TRIM(BOTH ' ' FROM TRIM(LEADING '0' FROM TRIM(BOTH '-' FROM (CASE 
        WHEN Score IS NOT NULL THEN CAST((Score * 100) / NULLIF(ViewCount, 0) AS TEXT)
        ELSE '0'
    END)))) AS Score_Percentage,
    CONCAT('Title: ', Title, ' | Author: ', Author, ' | Views: ', ViewCount, ' | Score: ', Score, 
           ' | Close Count: ', COALESCE(CloseCount, 0), ' | Close Reasons: ', COALESCE(CloseReasons, 'None')) AS PostDetails
FROM 
    TopRankedPosts
ORDER BY 
    Score DESC
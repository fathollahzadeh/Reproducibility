WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.PostTypeId,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 month'
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.PostTypeId
), PostHistoryData AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS HistoryCreationDate,
        ph.PostHistoryTypeId,
        ph.UserId,
        u.DisplayName AS EditorDisplayName,
        ph.Text AS HistoryDetail,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM 
        PostHistory ph
    JOIN 
        Users u ON ph.UserId = u.Id
    WHERE 
        ph.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '3 months'
        AND ph.PostHistoryTypeId IN (10, 11, 12)  
), BadgeCounts AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldCount,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverCount,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.CommentCount,
    CASE 
        WHEN rp.PostTypeId = 1 THEN 'Question'
        WHEN rp.PostTypeId = 2 THEN 'Answer'
        ELSE 'Other'
    END AS PostType,
    COALESCE(bc.BadgeCount, 0) AS UserBadgeCount,
    COALESCE(bc.GoldCount, 0) AS UserGoldCount,
    COALESCE(bc.SilverCount, 0) AS UserSilverCount,
    COALESCE(bc.BronzeCount, 0) AS UserBronzeCount,
    ph.HistoryDetail,
    ph.EditorDisplayName,
    ph.HistoryCreationDate
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistoryData ph ON rp.PostId = ph.PostId AND ph.HistoryRank = 1  
LEFT JOIN 
    BadgeCounts bc ON rp.PostId = ph.PostId 
WHERE 
    rp.RankByScore <= 10  
    AND (rp.CommentCount > 0 OR ph.HistoryCreationDate IS NOT NULL)
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC;
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= '2023-01-01' 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.PostTypeId
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5  
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COUNT(distinct b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostDetails AS (
    SELECT 
        tp.PostId,
        tp.Title,
        ta.TotalBounty,
        ta.BadgeCount,
        CASE
            WHEN tp.ViewCount < 100 THEN 'Low Engagement'
            WHEN tp.ViewCount BETWEEN 100 AND 1000 THEN 'Moderate Engagement'
            ELSE 'High Engagement'
        END AS EngagementLevel
    FROM 
        TopPosts tp
    LEFT JOIN 
        UserActivity ta ON tp.PostId = ta.UserId
)
SELECT 
    pd.Title,
    pd.EngagementLevel,
    COALESCE(pd.TotalBounty, 0) AS TotalBounty,
    COALESCE(pd.BadgeCount, 0) AS BadgeCount
FROM 
    PostDetails pd
LEFT JOIN 
    PostHistory ph ON pd.PostId = ph.PostId AND ph.PostHistoryTypeId NOT IN (12, 10) 
WHERE 
    pd.EngagementLevel = 'High Engagement' 
    AND pd.BadgeCount > 0
ORDER BY 
    pd.TotalBounty DESC, pd.BadgeCount DESC, pd.Title;
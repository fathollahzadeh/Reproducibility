WITH RankedPosts AS (
    
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CommentCount,
        ROW_NUMBER() OVER (ORDER BY p.CommentCount DESC, p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),

RecentEdits AS (
    
    SELECT 
        ph.PostId,
        ph.CreationDate AS EditDate,
        ph.UserDisplayName AS Editor,
        ph.Comment AS EditComment,
        ph.Text AS NewText,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS EditRank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5) 
),

UserBadgeCounts AS (
    
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)


SELECT 
    rp.Title,
    rp.Score,
    rp.CommentCount,
    re.EditDate,
    re.Editor,
    re.NewText,
    ub.BadgeCount
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentEdits re ON rp.PostId = re.PostId AND re.EditRank = 1 
JOIN 
    Users u ON rp.PostId = u.Id
JOIN 
    UserBadgeCounts ub ON u.Id = ub.UserId
WHERE 
    rp.Rank <= 10;
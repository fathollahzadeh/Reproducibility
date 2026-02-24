
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
        AND p.ViewCount > COALESCE((SELECT AVG(ViewCount) FROM Posts WHERE PostTypeId = 1), 0) 
        AND p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),
RankedPosts AS (
    SELECT 
        rp.*,
        ROW_NUMBER() OVER (PARTITION BY rp.OwnerDisplayName ORDER BY rp.Score DESC, rp.ViewCount DESC) AS Rank
    FROM 
        RecentPosts rp
)
SELECT 
    rp.OwnerDisplayName,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    COALESCE(b.BadgeCount, 0) AS BadgeCount,
    COALESCE(b.Class, 0) AS BadgeClass,
    rp.CreationDate,
    CASE 
        WHEN rp.Rank = 1 THEN 'Top Post'
        ELSE 'Regular Post'
    END AS PostType
FROM 
    RankedPosts rp
LEFT JOIN (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount,
        MAX(Class) AS Class
    FROM 
        Badges
    GROUP BY 
        UserId
) b ON rp.OwnerDisplayName = (SELECT DisplayName FROM Users WHERE Id = b.UserId)
WHERE 
    rp.Rank <= 3 
ORDER BY 
    rp.OwnerDisplayName, rp.Score DESC;

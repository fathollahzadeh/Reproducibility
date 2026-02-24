WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id, u.DisplayName, p.CreationDate, p.ViewCount
), 

TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(v.BountyAmount) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId AND v.VoteTypeId = 8
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        SUM(v.BountyAmount) > 0 
),

PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.ViewCount,
        rp.CommentCount,
        tu.TotalBounties,
        CASE 
            WHEN rp.CommentCount > 10 THEN 'Highly Engaged'
            WHEN rp.CommentCount BETWEEN 5 AND 10 THEN 'Moderately Engaged'
            ELSE 'Low Engagement' 
        END AS EngagementLevel
    FROM 
        RankedPosts rp
    LEFT JOIN 
        TopUsers tu ON rp.OwnerDisplayName = tu.DisplayName
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.OwnerDisplayName,
    ps.CreationDate,
    ps.ViewCount,
    ps.CommentCount,
    ps.TotalBounties,
    ps.EngagementLevel,
    COALESCE(tk.TagName, 'Uncategorized') AS MainTag
FROM 
    PostStatistics ps
LEFT JOIN 
    (SELECT DISTINCT 
         unnest(string_to_array(p.Tags, '>')) AS TagName, 
         p.Id AS PostID
     FROM 
         Posts p 
     WHERE 
         p.Tags IS NOT NULL) tk ON ps.PostId = tk.PostID
WHERE 
    ps.TotalBounties IS NOT NULL
ORDER BY 
    ps.ViewCount DESC, ps.CreationDate ASC
LIMIT 100;

WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
        ROW_NUMBER() OVER (ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.ViewCount, u.DisplayName
),
BadgeRanking AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        RANK() OVER (ORDER BY COUNT(b.Id) DESC) AS BadgeRank
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        COALESCE(r.BadgeCount, 0) AS BadgeCount,
        r.BadgeRank
    FROM 
        Users u
    LEFT JOIN 
        BadgeRanking r ON u.Id = r.UserId
)
SELECT 
    p.Title AS PostTitle,
    p.CreationDate AS Created_at,
    p.ViewCount,
    p.UpvoteCount,
    p.DownvoteCount,
    t.DisplayName AS TopUser,
    t.BadgeCount,
    t.BadgeRank,
    CASE 
        WHEN p.Score IS NULL THEN 'No Score'
        ELSE COALESCE(CAST(p.Score AS VARCHAR), 'Unknown')
    END AS Score,
    CASE 
        WHEN p.CommentCount > 0 THEN 'Has Comments'
        ELSE 'No Comments'
    END AS Comments_Status
FROM 
    RecentPosts p
LEFT JOIN 
    TopUsers t ON p.OwnerName = t.DisplayName
WHERE 
    p.PostRank <= 10
ORDER BY 
    p.ViewCount DESC;

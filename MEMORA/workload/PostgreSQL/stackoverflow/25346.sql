
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) AS UniqueVoterCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY COUNT(c.Id) DESC, SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Tags, p.PostTypeId
),
FilteredRankedPosts AS (
    SELECT * 
    FROM RankedPosts 
    WHERE Rank <= 10
)
SELECT 
    r.PostId,
    r.Title,
    r.Tags,
    r.CommentCount,
    r.UniqueVoterCount,
    r.UpvoteCount,
    r.DownvoteCount,
    b.Name AS UserBadge
FROM 
    FilteredRankedPosts r
LEFT JOIN 
    Users u ON r.PostId = u.Id 
LEFT JOIN 
    Badges b ON u.Id = b.UserId 
ORDER BY 
    r.UpvoteCount DESC, r.CommentCount DESC;

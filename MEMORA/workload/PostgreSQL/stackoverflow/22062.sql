WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.PostTypeId,
        COALESCE(COUNT(DISTINCT c.Id), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId 
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
    GROUP BY 
        p.Id
),

PostStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        COUNT(CASE WHEN bh.Id IS NOT NULL THEN 1 END) AS BadgeCount,
        rp.CommentCount,
        rp.Upvotes,
        rp.Downvotes,
        CASE 
            WHEN rp.CommentCount > 10 THEN 'Highly Discussed'
            WHEN rp.Upvotes > rp.Downvotes THEN 'More Liked'
            ELSE 'Less Popular'
        END AS Popularity
    FROM 
        RecentPosts rp
    LEFT JOIN 
        Badges bh ON bh.UserId = rp.OwnerUserId
    GROUP BY 
        rp.PostId, rp.Title, rp.CreationDate, rp.CommentCount, rp.Upvotes, rp.Downvotes
),

FAQ AS (
    SELECT 
        ps.PostId, 
        ps.Title, 
        ps.CreationDate,
        ps.CommentCount,
        ps.Upvotes,
        ps.Downvotes,
        ps.Popularity,
        EXTRACT(YEAR FROM ps.CreationDate) AS YearCreated,
        DENSE_RANK() OVER (ORDER BY ps.Upvotes DESC) AS Rank,
        CASE 
            WHEN EXISTS (
                SELECT 1 
                FROM Votes v 
                WHERE v.PostId = ps.PostId AND v.VoteTypeId = 1
            ) THEN 'Accepted'
            ELSE 'Not Accepted'
        END AS AcceptanceStatus
    FROM 
        PostStats ps
    WHERE 
        ps.Popularity = 'Highly Discussed'
)

SELECT 
    f.PostId,
    f.Title,
    f.CreationDate,
    f.CommentCount,
    f.Upvotes,
    f.Downvotes,
    f.Popularity,
    f.YearCreated,
    f.Rank,
    f.AcceptanceStatus,
    CASE 
        WHEN f.AcceptanceStatus = 'Accepted' THEN 'This post is actively endorsed by users!'
        ELSE 'This post has no accepted answers yet.'
    END AS UserMessage
FROM 
    FAQ f
WHERE 
    f.YearCreated = (SELECT MAX(EXTRACT(YEAR FROM CreationDate)) FROM Posts)
ORDER BY 
    f.Upvotes DESC, 
    f.CommentCount DESC
LIMIT 10;
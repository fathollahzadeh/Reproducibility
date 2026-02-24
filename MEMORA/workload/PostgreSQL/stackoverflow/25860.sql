
WITH Tags_CTE AS (
    SELECT 
        id, 
        tagname, 
        count, 
        REPLACE(LOWER(tagname), ' ', '-') AS normalized_tag_name
    FROM Tags
    WHERE count > 100
),
Post_Summary AS (
    SELECT 
        p.Id AS post_id,
        p.Title,
        p.CreationDate,
        p.Score,
        ARRAY_AGG(DISTINCT t.normalized_tag_name) AS associated_tags,
        COUNT(c.Id) AS comment_count,
        COUNT(DISTINCT ph.Id) AS history_count
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN 
        Tags_CTE t ON POSITION(t.normalized_tag_name IN LOWER(p.Tags)) > 0
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56'::timestamp - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score
),
User_Activity AS (
    SELECT 
        u.Id AS user_id,
        u.DisplayName,
        SUM(p.ViewCount) AS total_views,
        AVG(p.Score) AS average_score,
        COUNT(DISTINCT p.Id) AS total_posts,
        COUNT(DISTINCT b.Id) AS total_badges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    us.user_id, 
    us.DisplayName, 
    us.total_views, 
    us.average_score, 
    us.total_posts, 
    us.total_badges, 
    ps.post_id, 
    ps.Title, 
    ps.CreationDate, 
    ps.Score, 
    ps.associated_tags,
    ps.comment_count,
    ps.history_count
FROM 
    User_Activity us
JOIN 
    Post_Summary ps ON us.total_posts > 0
ORDER BY 
    us.total_views DESC, 
    ps.Score DESC
LIMIT 100;

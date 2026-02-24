
WITH TagCounts AS (
    SELECT 
        LOWER(TRIM(tag.tagName)) AS tag_name,
        COUNT(post.id) AS post_count
    FROM 
        Tags AS tag
    LEFT JOIN 
        Posts AS post ON post.Tags LIKE '%' || tag.TagName || '%'
    GROUP BY 
        LOWER(TRIM(tag.tagName))
),
UserBadges AS (
    SELECT 
        u.Id AS user_id,
        COUNT(b.Id) AS badge_count
    FROM 
        Users AS u
    LEFT JOIN 
        Badges AS b ON b.UserId = u.Id
    GROUP BY 
        u.Id
),
ActiveUsers AS (
    SELECT 
        u.DisplayName AS user_name,
        u.Reputation,
        u.CreationDate,
        u.LastAccessDate,
        ub.badge_count
    FROM 
        Users AS u
    JOIN 
        UserBadges AS ub ON u.Id = ub.user_id
    WHERE 
        u.LastAccessDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
        AND u.Reputation > 100
),
TopPosts AS (
    SELECT 
        p.Title,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS author_name,
        p.CreationDate,
        ARRAY_AGG(DISTINCT LOWER(TRIM(tag.tagName))) AS tags
    FROM 
        Posts AS p
    JOIN 
        Users AS u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Tags AS tag ON p.Tags LIKE '%' || tag.TagName || '%'
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Title, p.ViewCount, p.AnswerCount, p.CommentCount, u.DisplayName, p.CreationDate
    ORDER BY 
        p.ViewCount DESC
    LIMIT 10
)
SELECT 
    au.user_name,
    au.Reputation,
    au.badge_count,
    tp.Title AS post_title,
    tp.ViewCount,
    tp.AnswerCount,
    tp.CommentCount,
    tp.CreationDate,
    tc.post_count AS related_tags_count
FROM 
    ActiveUsers AS au
JOIN 
    TopPosts AS tp ON au.user_name = tp.author_name
JOIN 
    TagCounts AS tc ON tc.tag_name = ANY(tp.tags)
ORDER BY 
    au.Reputation DESC, tp.ViewCount DESC;

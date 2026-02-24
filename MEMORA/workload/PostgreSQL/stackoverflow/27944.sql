WITH tagged_posts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS Tag
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
), tag_stats AS (
    SELECT 
        Tag,
        COUNT(DISTINCT PostId) AS PostCount,
        COUNT(DISTINCT CASE WHEN p.OwnerUserId IS NOT NULL THEN p.OwnerUserId END) AS UniqueUserCount,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        tagged_posts t
    JOIN 
        Posts p ON t.PostId = p.Id
    GROUP BY 
        Tag
), user_badges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
), most_active_users AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.OwnerUserId
    ORDER BY 
        PostCount DESC
    LIMIT 10
), comprehensive_report AS (
    SELECT 
        t.Tag,
        t.PostCount,
        t.UniqueUserCount,
        t.LastPostDate,
        u.BadgeCount,
        COALESCE(a.PostCount, 0) AS ActivePostCount
    FROM 
        tag_stats t
    LEFT JOIN 
        user_badges u ON t.UniqueUserCount = u.UserId
    LEFT JOIN 
        most_active_users a ON u.UserId = a.OwnerUserId
)
SELECT 
    Tag,
    PostCount,
    UniqueUserCount,
    LastPostDate,
    BadgeCount,
    ActivePostCount
FROM 
    comprehensive_report
ORDER BY 
    PostCount DESC, 
    UniqueUserCount DESC;
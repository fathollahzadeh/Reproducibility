
WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(DISTINCT p.Id) > 10
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(c.Id) AS CommentCount,
        MAX(p.CreationDate) AS LastPostDate,
        DENSE_RANK() OVER (PARTITION BY u.Id ORDER BY COUNT(c.Id) DESC) AS Ranking
    FROM 
        Users u
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    us.DisplayName,
    us.TotalPosts,
    us.Questions,
    us.Answers,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges,
    pa.TagName,
    uac.CommentCount,
    uac.LastPostDate,
    CASE 
        WHEN uac.Ranking = 1 THEN 'Top Commenter'
        WHEN uac.CommentCount > 100 THEN 'Frequent Contributor'
        ELSE 'Regular User' 
    END AS UserCategory
FROM 
    UserStatistics us
LEFT JOIN 
    PopularTags pa ON pa.PostCount = (
        SELECT MAX(PostCount) 
        FROM PopularTags 
        WHERE TagName = pa.TagName
    )
LEFT JOIN 
    UserActivity uac ON uac.UserId = us.UserId
WHERE 
    us.TotalPosts > 5 
ORDER BY 
    us.UpVotes DESC, us.DownVotes ASC, uac.LastPostDate DESC
LIMIT 100;

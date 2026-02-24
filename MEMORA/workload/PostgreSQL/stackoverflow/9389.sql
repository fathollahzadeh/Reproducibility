
WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),
BadgeCounts AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges
    GROUP BY 
        UserId
),
PopularTags AS (
    SELECT 
        TRIM(UNNEST(string_to_array(Tags, ','))) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
    GROUP BY 
        TagName
    ORDER BY 
        TagCount DESC
    LIMIT 10
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.PostCount,
    us.Questions,
    us.Answers,
    us.UpVotes,
    us.DownVotes,
    COALESCE(bc.BadgeCount, 0) AS BadgeCount,
    pt.TagName,
    pt.TagCount
FROM 
    UserStatistics us
LEFT JOIN 
    BadgeCounts bc ON us.UserId = bc.UserId
JOIN 
    PopularTags pt ON pt.TagName IN (SELECT TRIM(UNNEST(string_to_array(us.DisplayName, ' '))))
ORDER BY 
    us.UpVotes DESC, us.PostCount DESC
LIMIT 100;

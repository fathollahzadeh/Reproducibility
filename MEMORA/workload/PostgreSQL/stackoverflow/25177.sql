
WITH TagFrequency AS (
    SELECT 
        tag,
        COUNT(*) AS tag_count
    FROM (
        SELECT 
            TRIM(UNNEST(string_to_array(SUBSTRING(Tags, 2, LENGTH(Tags) - 2), '><'))) AS tag
        FROM 
            Posts
        WHERE 
            PostTypeId = 1 
    ) AS UnnestedTags
    GROUP BY 
        tag
), 
TopTags AS (
    SELECT 
        tag, 
        tag_count
    FROM 
        TagFrequency
    ORDER BY 
        tag_count DESC
    LIMIT 5
),
UserActivity AS (
    SELECT 
        u.Id AS user_id,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS question_count,
        SUM(p.ViewCount) AS total_views,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS total_upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS total_downvotes
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        u.Id, u.DisplayName
),
TagContributions AS (
    SELECT 
        u.Id AS user_id,
        COUNT(DISTINCT p.Id) AS contributions,
        t.tag
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    JOIN 
        (SELECT 
            DISTINCT TRIM(UNNEST(string_to_array(SUBSTRING(Tags, 2, LENGTH(Tags) - 2), '><'))) AS tag
        FROM 
            Posts 
        WHERE 
            PostTypeId = 1) t ON POSITION(t.tag IN SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2)) > 0
    GROUP BY 
        u.Id, t.tag
),
FinalResults AS (
    SELECT 
        ua.DisplayName,
        ua.question_count,
        ua.total_views,
        ua.total_upvotes,
        ua.total_downvotes,
        tc.tag,
        tc.contributions
    FROM 
        UserActivity ua
    LEFT JOIN 
        TagContributions tc ON ua.user_id = tc.user_id
    WHERE 
        tc.tag IN (SELECT tag FROM TopTags)
)
SELECT 
    DisplayName, 
    question_count, 
    total_views, 
    total_upvotes, 
    total_downvotes, 
    tag, 
    contributions
FROM 
    FinalResults
ORDER BY 
    question_count DESC, 
    contributions DESC;

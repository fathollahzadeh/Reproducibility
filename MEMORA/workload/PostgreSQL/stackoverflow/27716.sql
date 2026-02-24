
WITH TagCounts AS (
    SELECT 
        UNNEST(string_to_array(SUBSTRING(Tags FROM 2 FOR LENGTH(Tags) - 2), '><')) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        TagName
),

PopularTags AS (
    SELECT 
        TagName,
        PostCount,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagCounts
    WHERE 
        PostCount > 5 
),

UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvotesReceived,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvotesReceived,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgesCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),

TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        QuestionCount,
        UpvotesReceived,
        DownvotesReceived,
        BadgesCount,
        RANK() OVER (ORDER BY UpvotesReceived DESC, QuestionCount DESC) AS UserRank
    FROM 
        UserEngagement
    WHERE 
        QuestionCount > 0
)

SELECT 
    t.TagName,
    t.PostCount,
    u.DisplayName AS TopUser,
    u.UpvotesReceived,
    u.QuestionCount,
    u.BadgesCount
FROM 
    PopularTags t
JOIN 
    TopUsers u ON EXISTS (
        SELECT 1 
        FROM Posts p 
        WHERE 
            p.OwnerUserId = u.UserId 
            AND p.PostTypeId = 1 
            AND p.Tags LIKE '%' || t.TagName || '%'
    )
WHERE 
    t.TagRank <= 10 
ORDER BY 
    t.PostCount DESC, 
    u.UpvotesReceived DESC;

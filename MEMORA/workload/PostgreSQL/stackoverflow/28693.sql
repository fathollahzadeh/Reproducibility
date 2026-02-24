
WITH TagCounts AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '><'))
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        TagCounts
    WHERE 
        PostCount >= 10 
),
UserScores AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS QuestionCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        SUM(b.Class) AS TotalBadgeScore
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
UserMetrics AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.QuestionCount,
        us.Upvotes,
        us.Downvotes,
        us.TotalBadgeScore,
        (us.Upvotes - us.Downvotes) AS Score,
        RANK() OVER (ORDER BY (us.Upvotes - us.Downvotes + us.TotalBadgeScore) DESC) AS UserRank
    FROM 
        UserScores us
)
SELECT 
    tt.TagName,
    um.DisplayName,
    um.QuestionCount,
    um.Upvotes,
    um.Downvotes,
    um.TotalBadgeScore,
    um.Score,
    um.UserRank
FROM 
    TopTags tt
JOIN 
    Posts p ON p.TAGS ILIKE '%' || tt.TagName || '%'
JOIN 
    UserMetrics um ON p.OwnerUserId = um.UserId
WHERE 
    um.UserRank <= 10 
ORDER BY 
    tt.TagName, um.UserRank;

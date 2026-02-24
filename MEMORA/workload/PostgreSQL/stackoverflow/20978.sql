
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes
    FROM 
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.CreationDate
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
),
TopTags AS (
    SELECT 
        TRIM(UNNEST(string_to_array(SUBSTRING(Tags FROM 2 FOR LENGTH(Tags) - 2), '><'))) AS Tag,
        COUNT(*) AS TagCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        Tag
    ORDER BY 
        TagCount DESC
    LIMIT 10
)
SELECT 
    us.DisplayName,
    us.Reputation,
    us.PostCount,
    us.QuestionCount,
    us.AnswerCount,
    upvote_count.Upvotes AS TotalUpvotes,
    downvote_count.Downvotes AS TotalDownvotes,
    r.PostId AS RecentPostId,
    r.Title AS RecentPost,
    r.CreationDate AS RecentPostDate,
    t.Tag,
    t.TagCount
FROM 
    UserStats us
LEFT JOIN 
    RecentPosts r ON us.UserId = r.OwnerUserId AND r.RecentRank = 1
LEFT JOIN 
    (SELECT p.OwnerUserId, COUNT(*) AS Upvotes 
     FROM Votes v
     JOIN Posts p ON v.PostId = p.Id
     WHERE v.VoteTypeId = 2
     GROUP BY p.OwnerUserId) AS upvote_count ON us.UserId = upvote_count.OwnerUserId
LEFT JOIN 
    (SELECT p.OwnerUserId, COUNT(*) AS Downvotes 
     FROM Votes v
     JOIN Posts p ON v.PostId = p.Id
     WHERE v.VoteTypeId = 3
     GROUP BY p.OwnerUserId) AS downvote_count ON us.UserId = downvote_count.OwnerUserId
CROSS JOIN 
    TopTags t
WHERE 
    us.Reputation >= 100
ORDER BY 
    us.Reputation DESC,
    us.PostCount DESC,
    t.TagCount DESC
LIMIT 20;

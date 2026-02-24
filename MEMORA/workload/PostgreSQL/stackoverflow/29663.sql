
WITH TagCounts AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS tag,
        COUNT(*) AS post_count
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        tag
),

TopTags AS (
    SELECT 
        tag,
        post_count,
        ROW_NUMBER() OVER (ORDER BY post_count DESC) AS rank
    FROM 
        TagCounts
),

UserEngagement AS (
    SELECT 
        u.Id AS user_id,
        u.DisplayName AS user_name,
        COUNT(DISTINCT p.Id) AS question_count,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS downvotes,
        COUNT(DISTINCT c.Id) AS comment_count
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        u.Id, u.DisplayName
),

TagUserEngagement AS (
    SELECT 
        tt.tag,
        ue.user_id,
        ue.user_name,
        ue.question_count,
        ue.upvotes,
        ue.downvotes,
        ue.comment_count,
        RANK() OVER (PARTITION BY tt.tag ORDER BY ue.upvotes DESC, ue.downvotes ASC) AS user_rank
    FROM 
        TopTags tt
    JOIN 
        Posts p ON p.Tags LIKE '%' || tt.tag || '%'
    JOIN 
        UserEngagement ue ON p.OwnerUserId = ue.user_id
)

SELECT 
    tag,
    user_id,
    user_name,
    question_count,
    upvotes,
    downvotes,
    comment_count,
    user_rank
FROM 
    TagUserEngagement
WHERE 
    user_rank <= 3 
ORDER BY 
    tag, user_rank;

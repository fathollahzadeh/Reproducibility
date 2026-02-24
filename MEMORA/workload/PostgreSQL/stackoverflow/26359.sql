
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        COALESCE(a.AnswerCount, 0) AS AnswerCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        (SELECT ParentId, COUNT(*) AS AnswerCount 
         FROM Posts 
         WHERE PostTypeId = 2 
         GROUP BY ParentId) a ON p.Id = a.ParentId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days' 
        AND p.PostTypeId IN (1, 2)  
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, u.DisplayName, a.AnswerCount
),
TopTags AS (
    SELECT 
        unnest(string_to_array(Tags, ',')) AS Tag,
        COUNT(*) AS TagCount
    FROM 
        RecentPosts
    GROUP BY 
        Tag
    ORDER BY 
        TagCount DESC 
    LIMIT 10
),
AggStats AS (
    SELECT 
        rp.OwnerDisplayName,
        COUNT(DISTINCT rp.PostId) AS TotalPosts,
        SUM(rp.CommentCount) AS TotalComments,
        SUM(rp.VoteCount) AS TotalVotes,
        SUM(rp.AnswerCount) AS TotalAnswers,
        ARRAY_AGG(DISTINCT tt.Tag) AS TopTags
    FROM 
        RecentPosts rp
    LEFT JOIN 
        TopTags tt ON tt.Tag = ANY(string_to_array(rp.Tags, ','))
    GROUP BY 
        rp.OwnerDisplayName
)
SELECT 
    OwnerDisplayName,
    TotalPosts,
    TotalComments,
    TotalVotes,
    TotalAnswers,
    TopTags
FROM 
    AggStats
ORDER BY 
    TotalPosts DESC;

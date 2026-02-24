
WITH TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalVotes,
        STRING_AGG(DISTINCT u.DisplayName, ', ') AS TopContributors
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id AND v.VoteTypeId IN (2, 3) 
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(DISTINCT p.Id) > 5 
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        Posts p 
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    WHERE 
        p.CreationDate > (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days')
        AND p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.OwnerDisplayName
),
TopTags AS (
    SELECT 
        ts.TagName,
        ts.QuestionCount,
        ts.CommentCount,
        ts.TotalVotes,
        ts.TopContributors,
        ROW_NUMBER() OVER (ORDER BY ts.TotalVotes DESC) AS TagRank
    FROM 
        TagStatistics ts
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.OwnerDisplayName,
    rp.CommentCount,
    tt.TagName,
    tt.QuestionCount,
    tt.TopContributors
FROM 
    RecentPosts rp
JOIN 
    TopTags tt ON rp.Title LIKE '%' || tt.TagName || '%'
WHERE 
    tt.TagRank <= 10 
ORDER BY 
    rp.CreationDate DESC, tt.TotalVotes DESC
LIMIT 50;
